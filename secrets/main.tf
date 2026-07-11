module "vault" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/hashicorp/vault?ref=v1.2.1"

  container_name = "platform-vault"
  data_path      = var.data_path
  config_path    = var.config_path
  api_port       = var.api_port
  network_name   = var.network_name
  # macOS Docker Desktop: drop = ["ALL"] causes CAP_SETFCAP errors;
  # explicit user conflicts with gosu. Override for local staging.
  drop_capabilities = var.drop_capabilities
  capabilities      = var.capabilities
  run_as_user       = var.run_as_user
  keys_path         = var.keys_path
  labels = {
    "platform.env"       = var.environment
    "platform.component" = "secrets"
  }
}
