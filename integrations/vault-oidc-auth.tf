# Vault JWT/OIDC auth backend — Authentik is the identity provider.
# Grants platform-admins and platform-users access to Vault via OIDC.

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

  # The Vault provider adds default tune fields on read that weren't explicitly
  # set. Ignoring prevents a perpetual diff on those provider-managed defaults.
  lifecycle {
    ignore_changes = [tune]
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
