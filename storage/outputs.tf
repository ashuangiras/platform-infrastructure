output "api_endpoint" {
  description = "MinIO S3 API endpoint from the host."
  value       = module.minio.api_endpoint
}

output "minio_api_endpoint" {
  description = "MinIO S3 API endpoint (alias)."
  value       = module.minio.api_endpoint
}

output "console_url" {
  description = "MinIO web console URL."
  value       = module.minio.console_url
}

output "container_name" {
  description = "MinIO container name (hostname on the Docker network)."
  value       = module.minio.container_name
}
