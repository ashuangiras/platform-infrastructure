module "vault" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/hashicorp/vault?ref=main"

  container_name = "platform-vault"
  data_path      = var.data_path
  config_path    = var.config_path
  api_port       = var.api_port
  network_name   = var.network_name

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "secrets"
  }
}
