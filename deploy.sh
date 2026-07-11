#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Fully automated platform deployment
#
# Usage:
#   ./deploy.sh            # full deploy (infra + integrations)
#   ./deploy.sh --destroy  # tear everything down cleanly
#   ./deploy.sh --plan     # show plan only, no apply
#
# What it does:
#   Stage 1 — Deploy infrastructure services (networking, storage, secrets,
#             discovery, data, identity). Vault is initialized and unsealed.
#   Stage 2 — Wait for all services to be healthy.
#   Stage 3 — Apply integrations (Vault KV credentials, Authentik OIDC apps,
#             Vault JWT auth, MinIO OIDC, user provisioning).
#
# Requirements:
#   - Docker Desktop running
#   - terraform, vault, mc, jq, curl in PATH
#   - terraform.tfvars with all required values
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Environment setup ─────────────────────────────────────────────────────────
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export VAULT_ADDR="http://localhost:8200"

KEYS_FILE="${VAULT_KEYS_PATH:-$HOME/.platform/vault-keys.json}"
PLAN_ONLY=false
DESTROY=false

for arg in "$@"; do
  case "$arg" in
    --plan)    PLAN_ONLY=true ;;
    --destroy) DESTROY=true ;;
    --help)
      echo "Usage: $0 [--plan|--destroy|--help]"
      exit 0 ;;
  esac
done

# ── Helper functions ──────────────────────────────────────────────────────────

log()  { echo "$(date '+%H:%M:%S') [deploy] $*"; }
ok()   { echo "$(date '+%H:%M:%S') [deploy] ✓ $*"; }
fail() { echo "$(date '+%H:%M:%S') [deploy] ✗ $*" >&2; exit 1; }

require_cmd() {
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || fail "Required command not found: $cmd — install it and retry."
  done
}

wait_healthy() {
  local name="$1" url="$2" interval="${3:-3}" max="${4:-60}"
  log "Waiting for $name at $url ..."
  for i in $(seq 1 "$max"); do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
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
  for i in $(seq 1 30); do
    STATUS=$(vault status -format=json 2>/dev/null || true)
    SEALED=$(echo "$STATUS" | jq -r '.sealed // "true"' 2>/dev/null || echo "true")
    [ "$SEALED" = "false" ] && ok "Vault is unsealed" && return 0
    sleep 2
  done
  fail "Vault did not unseal after 60s"
}

# ── Preflight checks ──────────────────────────────────────────────────────────

require_cmd terraform vault mc jq curl

log "Platform deploy starting — environment: $(terraform output -raw environment 2>/dev/null || grep 'environment' terraform.tfvars | head -1 | awk -F'"' '{print $2}')"

if $DESTROY; then
  log "DESTROY mode — tearing down all platform resources..."
  docker ps -a --format "{{.Names}}" 2>/dev/null | grep "^platform-" | xargs -r docker rm -f || true
  docker volume ls --format "{{.Name}}" 2>/dev/null | grep "^platform-" | xargs -r docker volume rm || true
  docker network ls --format "{{.Name}}" 2>/dev/null | grep "^platform-" | xargs -r docker network rm || true
  terraform destroy -auto-approve 2>/dev/null || true
  ok "Platform destroyed."
  exit 0
fi

if $PLAN_ONLY; then
  log "PLAN mode — setting up env vars for providers..."
  [ -f "$KEYS_FILE" ] && export VAULT_TOKEN="$(jq -r '.root_token' "$KEYS_FILE")" || export VAULT_TOKEN=""
  terraform init -upgrade -reconfigure >/dev/null
  terraform plan
  exit 0
fi

# ── Stage 1: Deploy infrastructure ───────────────────────────────────────────

log "Stage 1 — Deploying infrastructure services..."

terraform init -upgrade -reconfigure >/dev/null 2>&1

terraform apply \
  -target=module.networking \
  -target=module.storage \
  -target=module.secrets \
  -target=module.discovery \
  -target=module.data \
  -target=module.identity \
  -auto-approve

ok "Stage 1 complete — infrastructure deployed."

# ── Stage 2: Wait for all services ───────────────────────────────────────────

log "Stage 2 — Waiting for all services to be healthy..."

wait_vault_unsealed
wait_healthy "Authentik" "http://localhost:9080/-/health/ready/" 3 60
wait_healthy "MinIO"     "http://localhost:9000/minio/health/ready" 2 30
wait_healthy "Consul"    "http://localhost:8500/v1/status/leader" 2 20

ok "Stage 2 complete — all services healthy."

# ── Stage 3: Apply integrations ───────────────────────────────────────────────

log "Stage 3 — Configuring integrations (credentials, OIDC, users)..."

# Export runtime credentials for providers
export VAULT_TOKEN="$(jq -r '.root_token' "$KEYS_FILE")"

# Pass vault_token to Terraform (provider uses TF_VAR_ or explicit var)
TF_VAR_vault_token="$VAULT_TOKEN" terraform apply -auto-approve

ok "Stage 3 complete — integrations configured."

# ── Final summary ─────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║             Platform deployment complete                         ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Vault UI:     http://localhost:8200                             ║"
echo "║  Vault login:  vault login -method=oidc -path=oidc              ║"
echo "║  Authentik:    http://localhost:9080                             ║"
echo "║  MinIO:        http://localhost:9001                             ║"
echo "║  Consul:       http://localhost:8500                             ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Root token:   jq -r .root_token ~/.platform/vault-keys.json    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

terraform output
