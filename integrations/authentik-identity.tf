# Authentik — platform groups, service account, OIDC application definitions,
# and OIDC client secrets written back to Vault.

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

# ── OIDC application: Grafana ────────────────────────────────────────────────

module "oidc_grafana" {
  source = "./modules/oidc-application"

  name        = "Grafana"
  slug        = "grafana"
  description = "Grafana observability dashboard"
  meta_icon   = "https://grafana.com/static/img/menu/grafana2.svg"

  allowed_redirect_uris = [
    { matching_mode = "strict", url = "http://localhost:3000/login/generic_oauth" },
  ]

  authorization_flow_id = data.authentik_flow.default_authorization.id
  invalidation_flow_id  = data.authentik_flow.default_invalidation.id
  property_mapping_ids  = local.common_scope_mappings
}

# Write Grafana OIDC credentials to Vault
resource "vault_kv_secret_v2" "oidc_grafana" {
  mount = vault_mount.kv.path
  name  = "platform/oidc/grafana"

  data_json = jsonencode({
    client_id     = module.oidc_grafana.client_id
    client_secret = module.oidc_grafana.client_secret
    auth_url      = "${var.authentik_internal_url}/application/o/authorize/"
    token_url     = "${var.authentik_internal_url}/application/o/token/"
    api_url       = "${var.authentik_internal_url}/application/o/userinfo/"
    issuer_url    = "${var.authentik_internal_url}/application/o/grafana/"
  })
}
