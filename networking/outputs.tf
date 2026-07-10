output "network_id" {
  description = "Docker network ID."
  value       = module.docker_network.id
}

output "network_name" {
  description = "Docker network name — pass to other components as network_name."
  value       = module.docker_network.name
}

output "subnet" {
  description = "CIDR subnet of the network."
  value       = module.docker_network.subnet
}
