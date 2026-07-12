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

variable "capabilities" {
  description = "Linux capabilities to add. Set to [] on macOS Docker Desktop (IPC_LOCK causes loops)."
  type        = list(string)
  default     = ["IPC_LOCK"]
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

variable "logs_path" {
  description = "Host path for Vault audit logs. Mounted at /vault/logs. Create before apply."
  type        = string
  default     = ""
}

variable "tls_enabled" {
  description = "When true, Vault serves HTTPS and mounts the provided cert/key/CA."
  type        = bool
  default     = false
}

variable "tls_cert_path" {
  description = "Host path to the Vault server certificate (PEM). Mounted at /vault/tls/tls.crt."
  type        = string
  default     = ""
}

variable "tls_key_path" {
  description = "Host path to the Vault server private key (PEM). Mounted at /vault/tls/tls.key."
  type        = string
  default     = ""
}

variable "tls_ca_path" {
  description = "Host path to the CA certificate (PEM). Mounted at /vault/tls/ca.crt when set."
  type        = string
  default     = ""
}
