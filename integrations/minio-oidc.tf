# MinIO OIDC — configures Authentik as the identity provider via mc CLI.
# Idempotent: updates existing config or adds if absent.

# ---------------------------------------------------------------------------
# 5. MinIO — OIDC identity provider (via mc CLI)
# ---------------------------------------------------------------------------

resource "null_resource" "minio_oidc" {
  # Use sha256 of client_id+secret as trigger so output isn't suppressed by sensitive value
  triggers = {
    config_hash   = sha256("${module.oidc_minio.client_id}:${module.oidc_minio.client_secret}")
    authentik_url = var.authentik_internal_url
  }

  provisioner "local-exec" {
    command = <<-SHELL
      set -euo pipefail
      echo "[integrations] Configuring MinIO OIDC..."

      mc alias set platform "${var.minio_endpoint}" \
        "${var.minio_root_user}" "${var.minio_root_password}" --insecure

      # Check if config already exists (list returns JSON array)
      EXISTS=$(mc idp openid list platform --json --insecure 2>/dev/null \
        | jq '[.[] | select(.name == "authentik")] | length > 0' 2>/dev/null || echo "false")

      if [ "$EXISTS" = "true" ]; then
        echo "[integrations] Updating existing MinIO OIDC config..."
        mc idp openid update platform authentik \
          "config_url=${var.authentik_internal_url}/application/o/minio/.well-known/openid-configuration" \
          "client_id=${module.oidc_minio.client_id}" \
          "client_secret=${module.oidc_minio.client_secret}" \
          scopes=openid,email,profile \
          redirect_uri=http://localhost:9001/oauth_callback \
          display_name=Authentik \
          role_policy=consoleAdmin \
          --insecure
      else
        echo "[integrations] Adding MinIO OIDC config..."
        mc idp openid add platform authentik \
          "config_url=${var.authentik_internal_url}/application/o/minio/.well-known/openid-configuration" \
          "client_id=${module.oidc_minio.client_id}" \
          "client_secret=${module.oidc_minio.client_secret}" \
          scopes=openid,email,profile \
          redirect_uri=http://localhost:9001/oauth_callback \
          display_name=Authentik \
          role_policy=consoleAdmin \
          --insecure
      fi

      mc admin service restart platform --insecure
      echo "[integrations] MinIO OIDC configured."
    SHELL
  }

  depends_on = [module.oidc_minio, vault_mount.kv]
}
