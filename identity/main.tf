module "authentik" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/identity/authentik?ref=v1.1.0"

  container_name_prefix    = "platform-authentik"
  network_name             = var.network_name
  secret_key               = var.secret_key
  database_url             = var.database_url
  redis_url                = var.redis_url
  bootstrap_admin_password = var.bootstrap_admin_password
  bootstrap_admin_email    = var.bootstrap_admin_email
  http_port                = var.http_port
  https_port               = var.https_port
  run_as_user              = var.run_as_user
  error_reporting_enabled  = false

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "identity"
  }
}
