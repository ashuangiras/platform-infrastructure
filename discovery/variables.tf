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
