module "minio" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/storage/minio?ref=v1.6.0"

  container_name = "platform-minio"
  data_path      = var.data_path
  network_name   = var.network_name
  api_port       = var.api_port
  console_port   = var.console_port
  root_user      = var.root_user
  root_password  = var.root_password

  tls_enabled   = var.tls_enabled
  tls_cert_path = var.tls_cert_path
  tls_key_path  = var.tls_key_path
  tls_ca_path   = var.tls_ca_path

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "storage"
  }
}
