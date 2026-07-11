variable "network_name" {
  description = "Docker network name to attach the MinIO container to."
  type        = string
}

variable "data_path" {
  description = "Host path for MinIO data persistence."
  type        = string
}

variable "api_port" {
  description = "Host port for the MinIO S3 API."
  type        = number
}

variable "console_port" {
  description = "Host port for the MinIO web console."
  type        = number
}

variable "root_user" {
  description = "MinIO root username (sensitive — pass via TF_VAR or Vault)."
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "MinIO root password, ≥8 chars (sensitive)."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment label."
  type        = string
}
