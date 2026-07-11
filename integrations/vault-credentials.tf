# Vault KV v2 — enables the secret engine and writes all service credentials.
# Path schema: secret/platform/<service>/<credential-type>

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
