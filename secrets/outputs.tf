output "api_address" {
  description = "Vault API address from the host. Export as VAULT_ADDR."
  value       = module.vault.api_address
}

output "vault_api_address" {
  description = "Vault API address from the host (alias for api_address)."
  value       = module.vault.api_address
}

output "vault_root_token" {
  description = "Vault root token read from keys_path. Sensitive — only use in deploy.sh pipeline."
  value       = module.vault.root_token
  sensitive   = true
}

output "api_address_internal" {
  description = "Vault API address for containers on the platform network."
  value       = module.vault.api_address_internal
}

output "container_name" {
  description = "Vault container name (hostname on the Docker network)."
  value       = module.vault.container_name
}
