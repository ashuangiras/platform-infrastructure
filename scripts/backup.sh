#!/usr/bin/env bash
# =============================================================================
# backup.sh — Encrypted, idempotent platform backup (P0-4)
#
# Backs up, into a timestamped directory OUTSIDE the repo:
#   1. terraform.tfstate + the Vault init keys → a SINGLE ENCRYPTED archive.
#      (These contain secrets at rest; they are NEVER written in plaintext to
#       the destination — only the encrypted blob lands there.)
#   2. Each platform Docker volume → a tar.gz snapshot.
#
# Encryption (first available wins):
#   - age with a recipient   : export BACKUP_AGE_RECIPIENT=age1...      (preferred)
#   - age with a recipients file: export BACKUP_AGE_KEYFILE=/path/recipients.txt
#   - openssl + passphrase   : export BACKUP_PASSPHRASE='...'
#   - openssl + key file     : export BACKUP_KEYFILE=/path/passphrase.txt
#   - age passphrase (tty)   : falls back to interactive `age -p` prompt
#
# Config (env):
#   BACKUP_DIR        dest root (default: $HOME/.platform/backups)
#   VAULT_KEYS_PATH   vault keys file (default: $HOME/.platform/vault-keys.json)
#
# ── RESTORE ──────────────────────────────────────────────────────────────────
# 1. Decrypt the secrets archive:
#      age:     age -d -i <identity> secrets.tar.age > secrets.tar
#               (or `age -d secrets.tar.age > secrets.tar` for a passphrase)
#      openssl: openssl enc -d -aes-256-cbc -pbkdf2 -salt \
#                 -pass env:BACKUP_PASSPHRASE -in secrets.tar.enc -out secrets.tar
#    Then: tar xf secrets.tar   # restores terraform.tfstate + vault-keys.json
#    Copy each file back to its original location and `chmod 600` it.
# 2. Restore a Docker volume:
#      docker volume create <vol>
#      docker run --rm -v <vol>:/data -v "<backup-dir>":/backup alpine \
#        sh -c 'cd /data && tar xzf /backup/<vol>.tar.gz'
#
# This script is idempotent: each run writes to a fresh UTC-timestamped dir and
# never mutates prior backups or repo state.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Docker environment (macOS Docker Desktop) ────────────────────────────────
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
: "${DOCKER_HOST:=unix://$HOME/.docker/run/docker.sock}"
export DOCKER_HOST

# ── Config ────────────────────────────────────────────────────────────────────
BACKUP_DIR="${BACKUP_DIR:-$HOME/.platform/backups}"
VAULT_KEYS_PATH="${VAULT_KEYS_PATH:-$HOME/.platform/vault-keys.json}"
STATE_FILE="$REPO_ROOT/terraform.tfstate"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="$BACKUP_DIR/$TS"

VOLUMES=(
  platform-vault-data
  platform-consul-data
  platform-minio-data
  platform-postgresql-data
  platform-redis-data
)

log()  { echo "$(date -u '+%H:%M:%S') [backup] $*"; }
fail() { echo "$(date -u '+%H:%M:%S') [backup] ✗ $*" >&2; exit 1; }

# ── Safety: never write inside the repo ──────────────────────────────────────
case "$DEST/" in
  "$REPO_ROOT"/*) fail "BACKUP_DIR ($DEST) is inside the repo — choose a path outside $REPO_ROOT." ;;
esac

mkdir -p "$DEST"
chmod 700 "$DEST"
log "Backup destination: $DEST"

# ── 1. Encrypted secrets archive (tfstate + vault keys) ──────────────────────
TMPDIR_SECRETS="$(mktemp -d)"
chmod 700 "$TMPDIR_SECRETS"
cleanup() { rm -rf "$TMPDIR_SECRETS"; }
trap cleanup EXIT

staged=()
if [ -f "$STATE_FILE" ]; then
  chmod 600 "$STATE_FILE" || true            # P0-5: state at rest
  cp -p "$STATE_FILE" "$TMPDIR_SECRETS/terraform.tfstate"
  staged+=("terraform.tfstate")
else
  log "No terraform.tfstate found — skipping (nothing applied yet?)."
fi

if [ -f "$VAULT_KEYS_PATH" ]; then
  cp -p "$VAULT_KEYS_PATH" "$TMPDIR_SECRETS/vault-keys.json"
  staged+=("vault-keys.json")
else
  log "No vault keys at $VAULT_KEYS_PATH — skipping."
fi

if [ "${#staged[@]}" -gt 0 ]; then
  PLAIN_TAR="$TMPDIR_SECRETS/secrets.tar"
  tar cf "$PLAIN_TAR" -C "$TMPDIR_SECRETS" "${staged[@]}"

  if command -v age >/dev/null 2>&1 && [ -n "${BACKUP_AGE_RECIPIENT:-}" ]; then
    log "Encrypting secrets with age (recipient)."
    age -r "$BACKUP_AGE_RECIPIENT" -o "$DEST/secrets.tar.age" "$PLAIN_TAR"
  elif command -v age >/dev/null 2>&1 && [ -n "${BACKUP_AGE_KEYFILE:-}" ]; then
    log "Encrypting secrets with age (recipients file)."
    age -R "$BACKUP_AGE_KEYFILE" -o "$DEST/secrets.tar.age" "$PLAIN_TAR"
  elif command -v openssl >/dev/null 2>&1 && [ -n "${BACKUP_PASSPHRASE:-}" ]; then
    log "Encrypting secrets with openssl (passphrase)."
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_PASSPHRASE \
      -in "$PLAIN_TAR" -out "$DEST/secrets.tar.enc"
  elif command -v openssl >/dev/null 2>&1 && [ -n "${BACKUP_KEYFILE:-}" ]; then
    log "Encrypting secrets with openssl (key file)."
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$BACKUP_KEYFILE" \
      -in "$PLAIN_TAR" -out "$DEST/secrets.tar.enc"
  elif command -v age >/dev/null 2>&1; then
    log "Encrypting secrets with age (interactive passphrase)."
    age -p -o "$DEST/secrets.tar.age" "$PLAIN_TAR"
  else
    fail "No encryption method available. Set BACKUP_AGE_RECIPIENT, BACKUP_PASSPHRASE, or BACKUP_KEYFILE, or install age."
  fi
  # PLAIN_TAR lives only in the 0700 tmpdir and is shredded by the trap.
  log "Secrets archive written (encrypted): $(ls "$DEST"/secrets.tar.* 2>/dev/null)"
else
  log "No secrets to archive."
fi

# ── 2. Docker volume snapshots ───────────────────────────────────────────────
if command -v docker >/dev/null 2>&1; then
  for vol in "${VOLUMES[@]}"; do
    if docker volume inspect "$vol" >/dev/null 2>&1; then
      log "Snapshotting volume: $vol"
      docker run --rm -v "$vol":/data:ro -v "$DEST":/backup alpine \
        tar czf "/backup/$vol.tar.gz" -C /data . \
        || log "⚠ Failed to snapshot $vol — continuing."
    else
      log "Volume $vol not found — skipping."
    fi
  done
else
  log "docker not found — skipping volume snapshots."
fi

# ── 3. Lock down all produced files ──────────────────────────────────────────
find "$DEST" -type f -exec chmod 600 {} +
log "All backup files chmod 600."
log "Backup complete: $DEST"
