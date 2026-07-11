# Root orchestration — calls each platform component in dependency order.
# Every detail lives in the component directory; this file shows the full picture at a glance.

module "networking" {
  source = "./networking"

  subnet      = var.network_subnet
  gateway     = var.network_gateway
  environment = var.environment
}

module "storage" {
  source = "./storage"

  network_name  = module.networking.network_name
  data_path     = var.minio_data_path
  api_port      = var.minio_api_port
  console_port  = var.minio_console_port
  root_user     = var.minio_root_user
  root_password = var.minio_root_password
  environment   = var.environment

  depends_on = [module.networking]
}

module "secrets" {
  source = "./secrets"

  network_name      = module.networking.network_name
  data_path         = var.vault_data_path
  config_path       = var.vault_config_path
  api_port          = var.vault_port
  environment       = var.environment
  drop_capabilities = var.vault_drop_capabilities
  run_as_user       = var.vault_run_as_user

  depends_on = [module.networking]
}

module "discovery" {
  source = "./discovery"

  network_name = module.networking.network_name
  data_path    = var.consul_data_path
  config_path  = var.consul_config_path
  http_port    = var.consul_http_port
  dns_port     = var.consul_dns_port
  environment  = var.environment
  run_as_user  = var.consul_run_as_user

  depends_on = [module.networking]
}

module "data" {
  source = "./data"

  network_name             = module.networking.network_name
  pg_data_path             = var.pg_data_path
  pg_superuser_password    = var.pg_superuser_password
  pg_authentik_password    = var.pg_authentik_password
  redis_data_path          = var.redis_data_path
  redis_config_path        = var.redis_config_path
  redis_admin_password     = var.redis_admin_password
  redis_authentik_password = var.redis_authentik_password
  environment              = var.environment
  run_as_user              = var.data_run_as_user

  depends_on = [module.networking]
}

module "identity" {
  source = "./identity"

  network_name             = module.networking.network_name
  secret_key               = var.authentik_secret_key
  database_url             = module.data.postgresql_connections["authentik"].url
  redis_url                = module.data.redis_connections["authentik"].url
  bootstrap_admin_password = var.authentik_admin_password
  bootstrap_admin_email    = var.authentik_admin_email
  http_port                = var.authentik_http_port
  https_port               = var.authentik_https_port
  environment              = var.environment
  run_as_user              = var.data_run_as_user

  depends_on = [module.data]
}
