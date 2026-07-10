variable "network_name" {
  description = "Docker network to attach Vault to."
  type        = string
}

variable "data_path" {
  description = "Host path for Vault data (file storage backend)."
  type        = string
}

variable "config_path" {
  description = "Host path containing vault.hcl. See config/vault.hcl.example."
  type        = string
}

variable "api_port" {
  description = "Host port for the Vault API."
  type        = number
}

variable "environment" {
  description = "Environment label."
  type        = string
}
