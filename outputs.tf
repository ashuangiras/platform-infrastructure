# ── Network ────────────────────────────────────────────────────────────────
output "network_id" {
  description = "Docker network ID."
  value       = module.networking.network_id
}

output "network_subnet" {
  description = "CIDR subnet of the platform network."
  value       = module.networking.subnet
}

# ── Storage (MinIO) ────────────────────────────────────────────────────────
output "minio_api_endpoint" {
  description = "MinIO S3-compatible API endpoint (from the host). Use as Terraform state endpoint."
  value       = module.storage.api_endpoint
}

output "minio_console_url" {
  description = "MinIO web console URL."
  value       = module.storage.console_url
}

# ── Secrets (Vault) ────────────────────────────────────────────────────────
output "vault_api_address" {
  description = "Vault API address from the host. Export as VAULT_ADDR."
  value       = module.secrets.api_address
}

output "vault_api_address_internal" {
  description = "Vault API address for containers on the platform network."
  value       = module.secrets.api_address_internal
}

# ── Discovery (Consul) ─────────────────────────────────────────────────────
output "consul_http_address" {
  description = "Consul HTTP API and UI address from the host."
  value       = module.discovery.http_address
}

output "consul_http_address_internal" {
  description = "Consul HTTP address for containers on the platform network."
  value       = module.discovery.http_address_internal
}

output "consul_dns_address" {
  description = "Consul DNS address from the host."
  value       = module.discovery.dns_address
}

# ── State migration helper ─────────────────────────────────────────────────
output "state_migration_backend_config" {
  description = "S3 backend config snippet for backend-minio.hcl. Use after MinIO is running and the state bucket exists."
  value       = <<-EOT
    # backend-minio.hcl
    bucket                      = "platform-terraform-state"
    key                         = "platform-infrastructure/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "${module.storage.api_endpoint}"
    access_key                  = "<minio-access-key>"
    secret_key                  = "<minio-secret-key>"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  EOT
}
