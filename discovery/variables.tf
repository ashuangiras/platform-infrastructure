variable "network_name" {
  description = "Docker network to attach Consul to."
  type        = string
}

variable "data_path" {
  description = "Host path for Consul data (Raft + KV snapshots)."
  type        = string
}

variable "config_path" {
  description = "Host path containing consul.hcl. See config/consul.hcl.example."
  type        = string
}

variable "http_port" {
  description = "Host port for the Consul HTTP API and UI."
  type        = number
}

variable "dns_port" {
  description = "Host port for the Consul DNS interface."
  type        = number
}

variable "environment" {
  description = "Environment label."
  type        = string
}

variable "run_as_user" {
  description = "Container user. Set to empty string on macOS Docker Desktop (consul uses su-exec)."
  type        = string
  default     = ""
}

variable "https_port" {
  description = "Host port for the Consul HTTPS API (only exposed when tls_enabled = true)."
  type        = number
  default     = 8501
}

variable "tls_enabled" {
  description = "When true, Consul serves HTTPS on https_port and mounts the provided cert/key/CA."
  type        = bool
  default     = false
}

variable "tls_cert_path" {
  description = "Host path to the Consul server certificate (PEM). Mounted at /consul/tls/tls.crt."
  type        = string
  default     = ""
}

variable "tls_key_path" {
  description = "Host path to the Consul server private key (PEM). Mounted at /consul/tls/tls.key."
  type        = string
  default     = ""
}

variable "tls_ca_path" {
  description = "Host path to the CA certificate (PEM). Mounted at /consul/tls/ca.crt when set."
  type        = string
  default     = ""
}
