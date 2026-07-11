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
  keys_path         = var.vault_keys_path

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
}

module "identity" {
  source = "./identity"

  network_name             = module.networking.network_name
  secret_key               = var.authentik_secret_key
  pg_host                  = module.data.postgresql_host
  pg_port                  = module.data.postgresql_port
  pg_user                  = "authentik"
  pg_password              = var.pg_authentik_password
  pg_name                  = "authentik"
  redis_host               = module.data.redis_host
  redis_port               = module.data.redis_port
  redis_user               = "authentik"
  redis_password           = var.redis_authentik_password
  bootstrap_admin_password = var.authentik_admin_password
  bootstrap_admin_email    = var.authentik_admin_email
  bootstrap_token          = var.authentik_bootstrap_token
  http_port                = var.authentik_http_port
  https_port               = var.authentik_https_port
  environment              = var.environment
  run_as_user              = var.data_run_as_user
}

# ---------------------------------------------------------------------------
# Integrations — credential writes, OIDC wiring, user provisioning
#
# Requires all infra services to be healthy. deploy.sh performs a two-phase
# apply: Stage 1 deploys infra, Stage 2 applies integrations.
# ---------------------------------------------------------------------------
module "integrations" {
  source = "./integrations"

  # Vault
  vault_addr            = module.secrets.vault_api_address
  vault_token           = module.secrets.vault_root_token
  pg_superuser_password = var.pg_superuser_password
  pg_host               = module.data.postgresql_host
  pg_port               = module.data.postgresql_port
  pg_databases = {
    authentik = { user = "authentik", password = var.pg_authentik_password }
  }
  redis_host           = module.data.redis_host
  redis_port           = module.data.redis_port
  redis_admin_password = var.redis_admin_password
  redis_users = {
    authentik = { password = var.redis_authentik_password }
  }

  # Authentik
  authentik_url            = module.identity.authentik_http_url
  authentik_token          = var.authentik_bootstrap_token
  authentik_internal_url   = "http://platform-authentik-server:9000"
  authentik_admin_email    = var.authentik_admin_email
  authentik_admin_password = var.authentik_admin_password
  authentik_secret_key     = var.authentik_secret_key

  # MinIO
  minio_endpoint      = module.storage.minio_api_endpoint
  minio_root_user     = var.minio_root_user
  minio_root_password = var.minio_root_password

  environment = var.environment

  # Integrations providers need services running + healthy.
  # Ensures vault_init_unseal and authentik startup complete before integrations runs.
  depends_on = [module.secrets, module.identity, module.data]
}
