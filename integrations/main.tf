# =============================================================================
# integrations/main.tf
#
# Wires together all running platform services after they are deployed:
#   1. Vault KV v2  — enables secret engine + writes all service credentials
#   2. Authentik    — creates platform groups, users, and OIDC applications
#   3. Vault OIDC   — configures JWT/OIDC auth pointing at Authentik
#   4. MinIO OIDC   — configures MinIO identity provider via mc CLI
#
# Deployment order: call this component only after all infra modules are healthy.
# The deploy.sh script handles staged applies. Do not call this module in an
# initial apply where the services do not yet exist.
# =============================================================================

# ---------------------------------------------------------------------------
# 1. Vault — KV v2 secret engine + credential writes
# ---------------------------------------------------------------------------

resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "Platform KV v2 secrets engine"
}

# PostgreSQL superuser
resource "vault_kv_secret_v2" "pg_superuser" {
  mount = vault_mount.kv.path
  name  = "platform/postgresql/superuser"

  data_json = jsonencode({
    username = "postgres"
    password = var.pg_superuser_password
    host     = var.pg_host
    port     = tostring(var.pg_port)
    url      = "postgresql://postgres:${var.pg_superuser_password}@${var.pg_host}:${var.pg_port}/postgres"
  })
}

# PostgreSQL per-database credentials
resource "vault_kv_secret_v2" "pg_databases" {
  for_each = nonsensitive(tomap({ for k, v in var.pg_databases : k => v }))

  mount = vault_mount.kv.path
  name  = "platform/postgresql/databases/${each.key}"

  data_json = jsonencode({
    username = each.value.user
    password = each.value.password
    database = each.key
    host     = var.pg_host
    port     = tostring(var.pg_port)
    url      = "postgresql://${each.value.user}:${each.value.password}@${var.pg_host}:${var.pg_port}/${each.key}"
  })
}

# Redis admin
resource "vault_kv_secret_v2" "redis_admin" {
  mount = vault_mount.kv.path
  name  = "platform/redis/admin"

  data_json = jsonencode({
    username = "default"
    password = var.redis_admin_password
    host     = var.redis_host
    port     = tostring(var.redis_port)
  })
}

# Redis per-user credentials
resource "vault_kv_secret_v2" "redis_users" {
  for_each = nonsensitive(tomap({ for k, v in var.redis_users : k => v }))

  mount = vault_mount.kv.path
  name  = "platform/redis/users/${each.key}"

  data_json = jsonencode({
    username = each.key
    password = each.value.password
    host     = var.redis_host
    port     = tostring(var.redis_port)
    url      = "redis://${each.key}:${each.value.password}@${var.redis_host}:${var.redis_port}"
  })
}

# Authentik admin + secret key
resource "vault_kv_secret_v2" "authentik_admin" {
  mount = vault_mount.kv.path
  name  = "platform/authentik/admin"

  data_json = jsonencode({
    email    = var.authentik_admin_email
    password = var.authentik_admin_password
    url      = var.authentik_url
  })
}

resource "vault_kv_secret_v2" "authentik_secret_key" {
  mount = vault_mount.kv.path
  name  = "platform/authentik/secret-key"

  data_json = jsonencode({
    secret_key = var.authentik_secret_key
  })
}

# ---------------------------------------------------------------------------
# 3. Authentik — groups, users, OIDC providers, applications
# ---------------------------------------------------------------------------

# ── Groups (for_each over a locals map — add new groups here) ────────────────

locals {
  authentik_groups = {
    platform-admins = { is_superuser = true }
    platform-users  = { is_superuser = false }
    vault-users     = { is_superuser = false }
    minio-users     = { is_superuser = false }
  }
}

resource "authentik_group" "groups" {
  for_each     = local.authentik_groups
  name         = each.key
  is_superuser = each.value.is_superuser
}

# ── Platform service account ─────────────────────────────────────────────────
# A non-interactive service account used by Terraform and automation.

resource "authentik_user" "platform_svc" {
  username = "platform-svc"
  name     = "Platform Service Account"
  email    = "platform-svc@platform.local"
  type     = "service_account"
  groups   = [authentik_group.groups["platform-admins"].id]
}

# Write Authentik bootstrap token + platform-svc info to Vault
resource "vault_kv_secret_v2" "authentik_bootstrap_token" {
  mount = vault_mount.kv.path
  name  = "platform/authentik/bootstrap-token"

  data_json = jsonencode({
    token        = var.authentik_token
    service_user = "platform-svc"
    url          = var.authentik_url
    internal_url = var.authentik_internal_url
  })
}

# ── Default authorization + invalidation flows ───────────────────────────────

data "authentik_flow" "default_authorization" {
  slug = "default-provider-authorization-implicit-consent"

}

data "authentik_flow" "default_invalidation" {
  slug = "default-provider-invalidation-flow"

}

# ── OIDC scope mappings shared by all applications ──────────────────────────

# ── OIDC scope mappings shared by all applications ──────────────────────────────────────────

data "authentik_property_mapping_provider_scope" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}

data "authentik_property_mapping_provider_scope" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}

data "authentik_property_mapping_provider_scope" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}

locals {
  common_scope_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]
}

# ── OIDC applications (local module — one call per service) ──────────────────

module "oidc_vault" {
  source = "./modules/oidc-application"

  name        = "Vault"
  slug        = "vault"
  description = "HashiCorp Vault secret management"
  meta_icon   = "https://www.vaultproject.io/favicon.ico"

  allowed_redirect_uris = [
    { matching_mode = "strict", url = "${var.vault_addr}/ui/vault/auth/oidc/oidc/callback" },
    { matching_mode = "strict", url = "${var.vault_addr}/oidc/callback" },
  ]

  authorization_flow_id = data.authentik_flow.default_authorization.id
  invalidation_flow_id  = data.authentik_flow.default_invalidation.id
  property_mapping_ids  = local.common_scope_mappings
}

module "oidc_minio" {
  source = "./modules/oidc-application"

  name        = "MinIO"
  slug        = "minio"
  description = "MinIO object storage"
  meta_icon   = "https://min.io/favicon.ico"

  allowed_redirect_uris = [
    { matching_mode = "regex", url = "http://localhost:9001/oauth_callback" },
    { matching_mode = "regex", url = "http://localhost:9000/oauth_callback" },
  ]

  authorization_flow_id = data.authentik_flow.default_authorization.id
  invalidation_flow_id  = data.authentik_flow.default_invalidation.id
  property_mapping_ids  = local.common_scope_mappings
}

# Write OIDC client secrets to Vault
resource "vault_kv_secret_v2" "oidc_vault" {
  mount = vault_mount.kv.path
  name  = "platform/oidc/vault"

  data_json = jsonencode({
    client_id     = module.oidc_vault.client_id
    client_secret = module.oidc_vault.client_secret
    issuer_url    = "${var.authentik_internal_url}/application/o/vault/"
  })
}

resource "vault_kv_secret_v2" "oidc_minio" {
  mount = vault_mount.kv.path
  name  = "platform/oidc/minio"

  data_json = jsonencode({
    client_id     = module.oidc_minio.client_id
    client_secret = module.oidc_minio.client_secret
    issuer_url    = "${var.authentik_internal_url}/application/o/minio/"
  })
}

# ---------------------------------------------------------------------------
# 4. Vault — JWT/OIDC auth backend (Authentik as IdP)
# ---------------------------------------------------------------------------

# Vault policy: allows OIDC-authed users to read platform credentials
resource "vault_policy" "platform_reader" {
  name = "platform-reader"

  policy = <<-EOT
    # Read all platform credentials (granted to OIDC-authenticated users)
    path "secret/data/platform/*" {
      capabilities = ["read", "list"]
    }
    path "secret/metadata/platform/*" {
      capabilities = ["list"]
    }
  EOT

  depends_on = [vault_mount.kv]
}

resource "vault_policy" "platform_admin" {
  name = "platform-admin"

  policy = <<-EOT
    # Full access for platform admins
    path "secret/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "sys/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    path "auth/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
  EOT

  depends_on = [vault_mount.kv]
}

resource "vault_jwt_auth_backend" "authentik" {
  path               = "oidc"
  type               = "oidc"
  description        = "Authentik OIDC/JWT authentication"
  oidc_discovery_url = "${var.authentik_internal_url}/application/o/vault/"
  oidc_client_id     = module.oidc_vault.client_id
  oidc_client_secret = module.oidc_vault.client_secret

  tune {
    listing_visibility = "unauth"
  }

  depends_on = [vault_mount.kv]
}

resource "vault_jwt_auth_backend_role" "platform_admins" {
  backend   = vault_jwt_auth_backend.authentik.path
  role_name = "platform-admins"
  role_type = "oidc"

  oidc_scopes    = ["openid", "email", "profile"]
  user_claim     = "sub"
  groups_claim   = "groups"
  token_policies = [vault_policy.platform_admin.name]
  token_ttl      = 3600

  allowed_redirect_uris = [
    "${var.vault_addr}/ui/vault/auth/oidc/oidc/callback",
    "${var.vault_addr}/oidc/callback",
  ]
}

resource "vault_jwt_auth_backend_role" "platform_users" {
  backend   = vault_jwt_auth_backend.authentik.path
  role_name = "platform-users"
  role_type = "oidc"

  oidc_scopes    = ["openid", "email", "profile"]
  user_claim     = "sub"
  groups_claim   = "groups"
  token_policies = [vault_policy.platform_reader.name]
  token_ttl      = 3600

  allowed_redirect_uris = [
    "${var.vault_addr}/ui/vault/auth/oidc/oidc/callback",
    "${var.vault_addr}/oidc/callback",
  ]
}

# Map Authentik group names → Vault policies via identity groups
resource "vault_identity_group" "platform_admins" {
  name     = "platform-admins"
  type     = "external"
  policies = [vault_policy.platform_admin.name]
}

resource "vault_identity_group_alias" "platform_admins" {
  name           = "platform-admins"
  mount_accessor = vault_jwt_auth_backend.authentik.accessor
  canonical_id   = vault_identity_group.platform_admins.id
}

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
