module "consul" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/hashicorp/consul?ref=v1.1.3"

  container_name = "platform-consul"
  data_path      = var.data_path
  config_path    = var.config_path
  http_port      = var.http_port
  dns_port       = var.dns_port
  network_name   = var.network_name
  datacenter     = "platform-dc1"

  # macOS Docker Desktop: consul image uses su-exec; explicit user causes setgroups error
  run_as_user = var.run_as_user

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "discovery"
  }
}
