# ⚠ CONTRACT CHANGE — vault.hcl is now TERRAFORM-MANAGED (was operator-managed).
# Terraform writes ${var.config_path}/vault.hcl so the TLS cutover is deterministic
# and reversible: TLS listener when tls_enabled = true, plaintext (tls_disable = true)
# when false. Operators must NOT hand-edit this file anymore — change var.tls_enabled
# and re-apply. See config/vault.hcl.example for the documented content.
locals {
  vault_hcl_tls = <<-EOT
    storage "file" {
      path = "/vault/data"
    }

    listener "tcp" {
      address       = "0.0.0.0:8200"
      tls_disable   = false
      tls_cert_file = "/vault/tls/tls.crt"
      tls_key_file  = "/vault/tls/tls.key"
    }

    ui = true

    api_addr     = "https://127.0.0.1:8200"
    cluster_addr = "https://127.0.0.1:8201"
  EOT

  vault_hcl_plain = <<-EOT
    storage "file" {
      path = "/vault/data"
    }

    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = true
    }

    ui = true

    api_addr     = "http://0.0.0.0:8200"
    cluster_addr = "http://0.0.0.0:8201"
  EOT
}

resource "local_file" "vault_config" {
  filename        = "${var.config_path}/vault.hcl"
  content         = var.tls_enabled ? local.vault_hcl_tls : local.vault_hcl_plain
  file_permission = "0644"
}

module "vault" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/hashicorp/vault?ref=v1.6.0"

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
  logs_path         = var.logs_path

  tls_enabled   = var.tls_enabled
  tls_cert_path = var.tls_cert_path
  tls_key_path  = var.tls_key_path
  tls_ca_path   = var.tls_ca_path

  labels = {
    "platform.env"       = var.environment
    "platform.component" = "secrets"
  }

  # vault.hcl must be written before the container mounts config_path.
  depends_on = [local_file.vault_config]
}
