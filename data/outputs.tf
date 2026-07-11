output "postgresql_connections" {
  description = "Per-service PostgreSQL connection details. Written to Vault by integrations/."
  sensitive   = true
  value       = module.postgresql.connections
}

output "postgresql_host" {
  value = module.postgresql.host
}

output "postgresql_port" {
  value = module.postgresql.port
}

output "redis_connections" {
  description = "Per-service Redis connection details. Written to Vault by integrations/."
  sensitive   = true
  value       = module.redis.connections
}

output "redis_host" {
  value = module.redis.host
}

output "redis_port" {
  value = module.redis.port
}
