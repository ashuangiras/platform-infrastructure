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

  network_name = module.networking.network_name
  data_path    = var.vault_data_path
  config_path  = var.vault_config_path
  api_port     = var.vault_port
  environment  = var.environment

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

  depends_on = [module.networking]
}
