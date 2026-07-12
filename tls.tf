# =============================================================================
# tls.tf — Local self-signed TLS material for the platform (localhost hardening)
#
# Everything here is gated by var.tls_enabled. When tls_enabled = false the
# local_* file resources drop to zero instances, no material is written to disk,
# and the wrapper modules receive tls_enabled = false — restoring the previous
# plaintext behavior exactly.
#
# Trust chain:
#   tls_private_key.ca  +  tls_self_signed_cert.ca   → one local root CA
#   tls_private_key.service[svc] + tls_cert_request.service[svc]
#     + tls_locally_signed_cert.service[svc]          → per-service leaf certs
#
# Material is written OUTSIDE the repo, under local.tls_dir (default
# /srv/platform/tls). Private keys are mode 0600; certificates are mode 0644.
# The shared CA cert (local.tls_ca_cert) is bind-mounted into every service
# container by the wrapper modules.
# =============================================================================

locals {
  # Derived host directory for all generated TLS material (keys live OUTSIDE the repo).
  tls_dir = var.tls_material_path != "" ? var.tls_material_path : "${dirname(dirname(var.vault_config_path))}/tls"

  # Shared CA material.
  tls_ca_cert = "${local.tls_dir}/ca.crt"
  tls_ca_key  = "${local.tls_dir}/ca.key"

  # Per-service leaf certificate profiles.
  #   common_name — the primary DNS name (the container name on the Docker network)
  #   dns_names   — SANs; always include localhost + the container DNS name
  tls_services = {
    vault = {
      common_name = "platform-vault"
      dns_names   = ["localhost", "platform-vault"]
    }
    consul = {
      common_name = "platform-consul"
      dns_names   = ["localhost", "platform-consul"]
    }
    minio = {
      common_name = "platform-minio"
      dns_names   = ["localhost", "platform-minio"]
    }
    authentik = {
      common_name = "platform-authentik-server"
      dns_names   = ["localhost", "platform-authentik-server", "platform-authentik"]
    }
  }

  # Per-service host paths for the generated leaf cert + key (consumed by main.tf).
  vault_tls_cert     = "${local.tls_dir}/vault/tls.crt"
  vault_tls_key      = "${local.tls_dir}/vault/tls.key"
  consul_tls_cert    = "${local.tls_dir}/consul/tls.crt"
  consul_tls_key     = "${local.tls_dir}/consul/tls.key"
  minio_tls_cert     = "${local.tls_dir}/minio/tls.crt"
  minio_tls_key      = "${local.tls_dir}/minio/tls.key"
  authentik_tls_cert = "${local.tls_dir}/authentik/tls.crt"
  authentik_tls_key  = "${local.tls_dir}/authentik/tls.key"
}

# ── Root CA ──────────────────────────────────────────────────────────────────
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "Platform Local CA"
    organization = "platform-local"
  }

  # 10 years — this CA is local-only and never leaves the operator's machine.
  validity_period_hours = 87600

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# ── Per-service leaf certificates ────────────────────────────────────────────
resource "tls_private_key" "service" {
  for_each = local.tls_services

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "service" {
  for_each = local.tls_services

  private_key_pem = tls_private_key.service[each.key].private_key_pem
  dns_names       = each.value.dns_names
  ip_addresses    = ["127.0.0.1"]

  subject {
    common_name  = each.value.common_name
    organization = "platform-local"
  }
}

resource "tls_locally_signed_cert" "service" {
  for_each = local.tls_services

  cert_request_pem   = tls_cert_request.service[each.key].cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  # 1 year — rotate by re-running apply.
  validity_period_hours = 8760

  allowed_uses = [
    "server_auth",
    "digital_signature",
    "key_encipherment",
  ]
}

# ── Write material to disk (ALL gated on var.tls_enabled) ────────────────────
# CA private key — mode 0600, outside the repo.
resource "local_sensitive_file" "ca_key" {
  count = var.tls_enabled ? 1 : 0

  filename             = local.tls_ca_key
  content              = tls_private_key.ca.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

# CA certificate — mode 0644, bind-mounted into every service container.
resource "local_file" "ca_cert" {
  count = var.tls_enabled ? 1 : 0

  filename             = local.tls_ca_cert
  content              = tls_self_signed_cert.ca.cert_pem
  file_permission      = "0644"
  directory_permission = "0700"
}

# Per-service private keys — mode 0600.
resource "local_sensitive_file" "service_key" {
  for_each = var.tls_enabled ? local.tls_services : {}

  filename             = "${local.tls_dir}/${each.key}/tls.key"
  content              = tls_private_key.service[each.key].private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

# Per-service leaf certificates — mode 0644.
resource "local_file" "service_cert" {
  for_each = var.tls_enabled ? local.tls_services : {}

  filename             = "${local.tls_dir}/${each.key}/tls.crt"
  content              = tls_locally_signed_cert.service[each.key].cert_pem
  file_permission      = "0644"
  directory_permission = "0700"
}
