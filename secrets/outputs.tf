output "api_address" {
  description = "Vault API address from the host. Export as VAULT_ADDR."
  value       = module.vault.api_address
}

output "api_address_internal" {
  description = "Vault API address for containers on the platform network."
  value       = module.vault.api_address_internal
}

output "container_name" {
  description = "Vault container name (hostname on the Docker network)."
  value       = module.vault.container_name
}
