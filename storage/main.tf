module "minio" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/storage/minio?ref=main"

  container_name = "platform-minio"
  data_path      = var.data_path
  network_name   = var.network_name
  api_port       = var.api_port
  console_port   = var.console_port
  root_user      = var.root_user
  root_password  = var.root_password

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "storage"
  }
}
