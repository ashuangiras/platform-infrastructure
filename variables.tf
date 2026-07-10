# ── Host paths ──────────────────────────────────────────────────────────────
# Directories on the host where each service persists data.
# Create these before running terraform apply (see README.md).

variable "minio_data_path" {
  description = "Host path for MinIO data storage. Must exist and be writable by UID 1000."
  type        = string
  default     = "/srv/platform/minio/data"
}

variable "vault_data_path" {
  description = "Host path for Vault data storage. Must exist and be writable by UID 100."
  type        = string
  default     = "/srv/platform/vault/data"
}

variable "vault_config_path" {
  description = "Host path containing vault.hcl. Must exist and contain a valid config before apply."
  type        = string
  default     = "/srv/platform/vault/config"
}

variable "consul_data_path" {
  description = "Host path for Consul data storage. Must exist and be writable by UID 100."
  type        = string
  default     = "/srv/platform/consul/data"
}

variable "consul_config_path" {
  description = "Host path containing consul.hcl. Must exist and contain a valid config before apply."
  type        = string
  default     = "/srv/platform/consul/config"
}

# ── Networking ───────────────────────────────────────────────────────────────

variable "network_subnet" {
  description = "CIDR block for the platform Docker network."
  type        = string
  default     = "10.100.0.0/24"
}

variable "network_gateway" {
  description = "Gateway address for the platform Docker network."
  type        = string
  default     = "10.100.0.1"
}

# ── MinIO ────────────────────────────────────────────────────────────────────

variable "minio_root_user" {
  description = "MinIO root (admin) username. Set via TF_VAR_minio_root_user or a tfvars file."
  type        = string
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root (admin) password, ≥8 characters. Set via TF_VAR_minio_root_password or a tfvars file."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.minio_root_password) >= 8
    error_message = "minio_root_password must be at least 8 characters."
  }
}

# ── Ports (all optional, defaults match each service's standard port) ─────────

variable "minio_api_port" {
  description = "Host port for MinIO S3 API."
  type        = number
  default     = 9000
}

variable "minio_console_port" {
  description = "Host port for MinIO web console."
  type        = number
  default     = 9001
}

variable "vault_port" {
  description = "Host port for Vault API."
  type        = number
  default     = 8200
}

variable "consul_http_port" {
  description = "Host port for Consul HTTP API and UI."
  type        = number
  default     = 8500
}

variable "consul_dns_port" {
  description = "Host port for Consul DNS."
  type        = number
  default     = 8600
}

# ── Environment label ─────────────────────────────────────────────────────────

variable "environment" {
  description = "Environment name applied as a label to all containers and the Docker network."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment must be one of: production, staging, development."
  }
}
