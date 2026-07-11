output "api_endpoint" {
  description = "MinIO S3 API endpoint from the host. Use as the Terraform S3 backend endpoint."
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
