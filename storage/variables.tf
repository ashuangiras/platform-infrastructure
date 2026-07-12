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

variable "tls_enabled" {
  description = "When true, MinIO serves HTTPS and mounts the provided cert/key/CA."
  type        = bool
  default     = false
}

variable "tls_cert_path" {
  description = "Host path to the MinIO server certificate (PEM). Mounted at /certs/public.crt."
  type        = string
  default     = ""
}

variable "tls_key_path" {
  description = "Host path to the MinIO server private key (PEM). Mounted at /certs/private.key."
  type        = string
  default     = ""
}

variable "tls_ca_path" {
  description = "Host path to the CA certificate (PEM). Mounted at /certs/CAs/ca.crt when set."
  type        = string
  default     = ""
}
