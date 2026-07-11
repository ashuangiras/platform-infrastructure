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

# ── State backend reference ────────────────────────────────────────────────
output "minio_s3_endpoint" {
  description = "MinIO S3 endpoint to put in backend.hcl as the 'endpoint' value."
  value       = module.storage.api_endpoint
}

# ── Data (PostgreSQL + Redis) ──────────────────────────────────────────────────
output "postgresql_host" {
  description = "PostgreSQL container hostname on the Docker network."
  value       = module.data.postgresql_host
}

# ── Identity (Authentik) ──────────────────────────────────────────────────────
output "authentik_http_url" {
  description = "Authentik HTTP URL from the host. Default: http://localhost:9000"
  value       = module.identity.authentik_http_url
}

output "authentik_issuer_url" {
  description = "Authentik OIDC issuer URL — configure in Vault JWT auth and Grafana OAuth2."
  value       = module.identity.authentik_issuer_url
}
