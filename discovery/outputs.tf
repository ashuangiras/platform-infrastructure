output "http_address" {
  description = "Consul HTTP API and UI address from the host."
  value       = module.consul.http_address
}

output "http_address_internal" {
  description = "Consul HTTP address for containers on the platform network."
  value       = module.consul.http_address_internal
}

output "dns_address" {
  description = "Consul DNS address from the host."
  value       = module.consul.dns_address
}

output "container_name" {
  description = "Consul container name (hostname on the Docker network)."
  value       = module.consul.container_name
}
