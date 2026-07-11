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

variable "drop_capabilities" {
  description = "Linux capabilities to drop. Set to [] on macOS Docker Desktop."
  type        = list(string)
  default     = ["ALL"]
}

variable "run_as_user" {
  description = "Container user. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = "100:1000"
}

variable "keys_path" {
  description = "Path where Vault init output (unseal keys + root token) is stored. Never commit this file."
  type        = string
  default     = "~/.platform/vault-keys.json"
}
