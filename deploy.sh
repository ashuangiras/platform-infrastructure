#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Platform deployment with a plan-review gate (IAC-002)
#
# Usage:
#   ./deploy.sh            # plan → confirm → apply (infra + integrations)
#   ./deploy.sh --yes      # same, but auto-approve (non-interactive)
#   ./deploy.sh --plan     # plan only, no apply
#   ./deploy.sh --destroy  # tear everything down cleanly
#   ./deploy.sh --help
#
# PLAN GATE (IAC-002): every apply is preceded by a SAVED plan
# (`terraform plan -out=tfplan`), a printed summary, and an explicit
# confirmation. The apply runs the SAVED plan file — never a blind
# `-auto-approve` of a fresh plan.
#
# Stages:
#   Stage 1 — Deploy infrastructure services (networking, storage, secrets,
#             discovery, data, identity). Vault is initialized and unsealed.
#   Stage 2 — Wait for all services to be healthy.
#   Stage 3 — Apply integrations (Vault KV credentials, Authentik OIDC apps,
#             Vault JWT auth, MinIO OIDC, user provisioning).
#
# TLS (P0-1): when tls_enabled = true (default) in terraform.tfvars, this script
# exports the runtime trust needed for the local self-signed CA:
#   - VAULT_ADDR (https) + VAULT_CACERT      → vault CLI + vault provider
#   - SSL_CERT_FILE = <tls_dir>/ca.crt       → authentik provider (Go trust store;
#                                              the provider has NO ca_cert_file arg)
# SSL_CERT_FILE is exported ONLY AFTER `terraform init` completes and the CA
# exists on disk — exporting it before init would override the system CA bundle
# and break provider downloads from the Terraform registry.
#
# ⚠ LOCAL BACKEND HAS NO STATE LOCKING (ADR-0014/0020). Run ONE deploy at a
#   time — concurrent applies will corrupt terraform.tfstate. State contains
#   secrets at rest and is chmod 600 after every apply (P0-5).
#
# Requirements:
#   - Docker Desktop running
#   - terraform, vault, mc, jq, curl in PATH
#   - terraform.tfvars with REAL secrets (placeholders are rejected — see P0-6)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Flags ─────────────────────────────────────────────────────────────────────
PLAN_ONLY=false
DESTROY=false
ASSUME_YES=false

for arg in "$@"; do
  case "$arg" in
    --plan)     PLAN_ONLY=true ;;
    --destroy)  DESTROY=true ;;
    --yes|-y)   ASSUME_YES=true ;;
    --help|-h)  echo "Usage: $0 [--plan|--destroy|--yes|--help]"; exit 0 ;;
    *)          echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "$(date '+%H:%M:%S') [deploy] $*"; }
ok()   { echo "$(date '+%H:%M:%S') [deploy] ✓ $*"; }
fail() { echo "$(date '+%H:%M:%S') [deploy] ✗ $*" >&2; exit 1; }

# Best-effort scalar reader for terraform.tfvars (strips quotes + inline comments).
tfvar() {
  [ -f terraform.tfvars ] || return 0
  # `|| true` keeps the function set -e / pipefail safe when the key is ABSENT
  # (grep returns 1 on no-match). Callers rely on an empty result for optional keys.
  { grep -E "^[[:space:]]*$1[[:space:]]*=" terraform.tfvars | head -1 \
    | sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]*#.*$//; s/^"//; s/"$//'; } || true
}
tfvar_or() { local v; v="$(tfvar "$1")"; echo "${v:-$2}"; }

require_cmd() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || fail "Required command not found: $cmd — install it and retry."
  done
}

# P0-6: refuse to deploy with placeholder secrets in terraform.tfvars.
guard_secrets() {
  [ -f terraform.tfvars ] || fail "terraform.tfvars not found — copy terraform.tfvars.example and fill in REAL secrets."
  if grep -iEq 'please-change|replace_me|change-me|staging-' terraform.tfvars; then
    echo "──────────────────────────────────────────────────────────────────" >&2
    grep -inE 'please-change|replace_me|change-me|staging-' terraform.tfvars >&2 || true
    echo "──────────────────────────────────────────────────────────────────" >&2
    fail "terraform.tfvars contains placeholder secrets (above). Generate real values (e.g. openssl rand -base64 24) before deploying."
  fi
}

confirm_apply() {
  $ASSUME_YES && { log "--yes supplied — applying without prompt."; return 0; }
  local reply
  read -r -p "Apply this plan? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) fail "Apply aborted by operator." ;;
  esac
}

# plan_and_apply <extra terraform plan args...>
# Saves a plan, prints a summary, confirms, then applies the SAVED plan file.
plan_and_apply() {
  log "Planning (terraform plan -out=tfplan $*)"
  terraform plan -out=tfplan "$@"
  local summary
  summary="$(terraform show -no-color tfplan 2>/dev/null | grep -E '^(Plan:|No changes)' | tail -1)"
  echo "──────────────────────────────────────────────────────────────────"
  log "Plan summary: ${summary:-review the plan output above}"
  echo "──────────────────────────────────────────────────────────────────"
  confirm_apply
  terraform apply tfplan
  chmod 600 terraform.tfstate 2>/dev/null || true   # P0-5: state at rest
}

# ── Environment setup ─────────────────────────────────────────────────────────
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

KEYS_FILE="${VAULT_KEYS_PATH:-$HOME/.platform/vault-keys.json}"

# TLS toggle mirrors var.tls_enabled (default true when unset in tfvars).
if [ "$(tfvar_or tls_enabled true)" = "false" ]; then TLS_ON=false; else TLS_ON=true; fi

# Derive the CA path the providers/CLI must trust (mirrors local.tls_dir in tls.tf).
VAULT_CFG="$(tfvar_or vault_config_path /srv/platform/vault/config)"
TLS_MATERIAL="$(tfvar tls_material_path)"
if [ -n "$TLS_MATERIAL" ]; then
  TLS_DIR="$TLS_MATERIAL"
else
  TLS_DIR="$(dirname "$(dirname "$VAULT_CFG")")/tls"
fi
CA_CERT="$TLS_DIR/ca.crt"

CURL_TLS_OPTS=()
if $TLS_ON; then
  export VAULT_ADDR="https://127.0.0.1:$(tfvar_or vault_port 8200)"
  export VAULT_CACERT="$CA_CERT"
  CURL_TLS_OPTS=(--cacert "$CA_CERT")
  log "TLS is ENABLED — vault/authentik providers will verify against $CA_CERT"
else
  export VAULT_ADDR="http://localhost:8200"
  log "TLS is DISABLED — plaintext deployment (rollback mode)."
fi

# Export SSL_CERT_FILE for the authentik provider ONLY once the CA exists and
# AFTER init has run (see header). Called after Stage 1.
export_ssl_trust() {
  $TLS_ON || return 0
  if [ -f "$CA_CERT" ]; then
    export SSL_CERT_FILE="$CA_CERT"
    log "Exported SSL_CERT_FILE=$CA_CERT (authentik provider trust)."
  else
    log "⚠ CA cert $CA_CERT not present yet — SSL_CERT_FILE not exported."
  fi
}

# Health-check endpoints (TLS-aware). Consul keeps http on 8500 even with TLS.
if $TLS_ON; then
  AUTHENTIK_HEALTH="https://127.0.0.1:$(tfvar_or authentik_https_port 9444)/-/health/ready/"
  MINIO_HEALTH="https://127.0.0.1:$(tfvar_or minio_api_port 9000)/minio/health/ready"
else
  AUTHENTIK_HEALTH="http://localhost:9080/-/health/ready/"
  MINIO_HEALTH="http://localhost:9000/minio/health/ready"
fi
CONSUL_HEALTH="http://localhost:8500/v1/status/leader"

wait_healthy() {
  local name="$1" url="$2" interval="${3:-3}" max="${4:-60}"
  log "Waiting for $name at $url ..."
  for _ in $(seq 1 "$max"); do
    code=$(curl -s "${CURL_TLS_OPTS[@]}" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [ "$code" = "200" ] || [ "$code" = "204" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
      ok "$name is ready (HTTP $code)"
      return 0
    fi
    sleep "$interval"
  done
  fail "$name did not become healthy at $url after $((max * interval))s"
}

wait_vault_unsealed() {
  log "Waiting for Vault to be unsealed ..."
  for _ in $(seq 1 30); do
    STATUS=$(vault status -format=json 2>/dev/null || true)
    SEALED=$(echo "$STATUS" | jq -r '.sealed // "true"' 2>/dev/null || echo "true")
    [ "$SEALED" = "false" ] && ok "Vault is unsealed" && return 0
    sleep 2
  done
  fail "Vault did not unseal after 60s"
}

# ── Preflight ─────────────────────────────────────────────────────────────────
require_cmd terraform vault mc jq curl

if $DESTROY; then
  log "DESTROY mode — tearing down all platform resources..."
  docker ps -a --format "{{.Names}}" 2>/dev/null | grep "^platform-" | xargs -r docker rm -f || true
  docker volume ls --format "{{.Name}}" 2>/dev/null | grep "^platform-" | xargs -r docker volume rm || true
  docker network ls --format "{{.Name}}" 2>/dev/null | grep "^platform-" | xargs -r docker network rm || true
  terraform destroy -auto-approve 2>/dev/null || true
  ok "Platform destroyed."
  exit 0
fi

# Placeholder-secret guard applies to every plan/apply path (not --destroy).
guard_secrets

log "Platform deploy starting — environment: $(tfvar_or environment production)"

# ── Init (must run BEFORE SSL_CERT_FILE is exported) ─────────────────────────
terraform init -upgrade -reconfigure >/dev/null

if $PLAN_ONLY; then
  log "PLAN mode — no apply will be performed."
  [ -f "$KEYS_FILE" ] && export VAULT_TOKEN="$(jq -r '.root_token' "$KEYS_FILE")" || export VAULT_TOKEN=""
  export_ssl_trust
  terraform plan
  exit 0
fi

# ── Stage 1: Deploy infrastructure ───────────────────────────────────────────
log "Stage 1 — Deploying infrastructure services..."

plan_and_apply \
  -target=module.networking \
  -target=module.storage \
  -target=module.secrets \
  -target=module.discovery \
  -target=module.data \
  -target=module.identity

ok "Stage 1 complete — infrastructure deployed."

# CA now exists on disk — export trust for the providers/CLI.
export_ssl_trust

# ── Stage 2: Wait for all services ───────────────────────────────────────────
log "Stage 2 — Waiting for all services to be healthy..."

wait_vault_unsealed
wait_healthy "Authentik" "$AUTHENTIK_HEALTH" 3 60
wait_healthy "MinIO"     "$MINIO_HEALTH" 2 30
wait_healthy "Consul"    "$CONSUL_HEALTH" 2 20

ok "Stage 2 complete — all services healthy."

# ── Stage 3: Apply integrations ───────────────────────────────────────────────
log "Stage 3 — Configuring integrations (credentials, OIDC, users)..."

# Export runtime credentials for providers.
export VAULT_TOKEN="$(jq -r '.root_token' "$KEYS_FILE")"

TF_VAR_vault_token="$VAULT_TOKEN" plan_and_apply

ok "Stage 3 complete — integrations configured."

# ── Final summary ─────────────────────────────────────────────────────────────
if $TLS_ON; then SCHEME=https; VHOST="127.0.0.1"; else SCHEME=http; VHOST="localhost"; fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║             Platform deployment complete                         ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Vault UI:     ${SCHEME}://${VHOST}:8200"
echo "║  Vault login:  vault login -method=oidc -path=oidc"
echo "║  Authentik:    ${SCHEME}://${VHOST}:$( $TLS_ON && echo 9444 || echo 9080 )"
echo "║  MinIO:        ${SCHEME}://${VHOST}:9001"
echo "║  Consul:       http://localhost:8500"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Root token:   jq -r .root_token ${KEYS_FILE}"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

terraform output
