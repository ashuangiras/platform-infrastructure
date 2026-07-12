module "authentik" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/identity/authentik?ref=v1.6.0"

  container_name_prefix    = "platform-authentik"
  network_name             = var.network_name
  secret_key               = var.secret_key
  pg_host                  = var.pg_host
  pg_port                  = var.pg_port
  pg_user                  = var.pg_user
  pg_password              = var.pg_password
  pg_name                  = var.pg_name
  redis_host               = var.redis_host
  redis_port               = var.redis_port
  redis_user               = var.redis_user
  redis_password           = var.redis_password
  bootstrap_admin_password = var.bootstrap_admin_password
  bootstrap_admin_email    = var.bootstrap_admin_email
  bootstrap_token          = var.bootstrap_token
  http_port                = var.http_port
  https_port               = var.https_port
  run_as_user              = var.run_as_user
  error_reporting_enabled  = false

  tls_enabled   = var.tls_enabled
  tls_cert_path = var.tls_cert_path
  tls_key_path  = var.tls_key_path
  tls_ca_path   = var.tls_ca_path

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "identity"
  }
}
