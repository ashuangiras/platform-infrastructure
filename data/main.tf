module "postgresql" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/data/postgresql?ref=v1.1.2"

  container_name     = "platform-postgresql"
  data_path          = var.pg_data_path
  network_name       = var.network_name
  superuser_password = var.pg_superuser_password
  run_as_user        = var.run_as_user

  databases = {
    authentik = { password = var.pg_authentik_password }
  }

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "data"
  }
}

module "redis" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/data/redis?ref=v1.1.0"

  container_name = "platform-redis"
  data_path      = var.redis_data_path
  config_path    = var.redis_config_path
  network_name   = var.network_name
  admin_password = var.redis_admin_password
  run_as_user    = var.run_as_user

  acl_users = {
    authentik = {
      password = var.redis_authentik_password
      commands = "+@all"
      # key_prefix = "" means ~* (all keys). Celery (used by Authentik worker) writes
      # arbitrary key names (unacked_mutex, celery*, _kombu* etc.) that don't match
      # a service-specific prefix. Authentication via username+password is the security
      # boundary; key prefix restriction is overly narrow here.
      key_prefix = ""
    }
  }

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "data"
  }
}
