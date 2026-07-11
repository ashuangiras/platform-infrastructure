variable "network_name" { type = string }
variable "secret_key" {
  type      = string
  sensitive = true
}
variable "pg_host" {
  description = "PostgreSQL hostname on the Docker network."
  type        = string
}
variable "pg_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}
variable "pg_user" {
  description = "PostgreSQL username for Authentik."
  type        = string
  default     = "authentik"
}
variable "pg_password" {
  description = "PostgreSQL password for Authentik."
  type        = string
  sensitive   = true
}
variable "pg_name" {
  description = "PostgreSQL database name for Authentik."
  type        = string
  default     = "authentik"
}
variable "redis_host" {
  description = "Redis hostname on the Docker network."
  type        = string
}
variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}
variable "redis_user" {
  description = "Redis ACL username for Authentik."
  type        = string
  default     = "authentik"
}
variable "redis_password" {
  description = "Redis ACL password for Authentik."
  type        = string
  sensitive   = true
}
variable "bootstrap_admin_password" {
  type      = string
  sensitive = true
}
variable "bootstrap_token" {
  description = "Authentik bootstrap API token (AUTHENTIK_BOOTSTRAP_TOKEN)."
  type        = string
  sensitive   = true
  default     = ""
}
variable "http_port" {
  type    = number
  default = 9080
}
variable "https_port" {
  type    = number
  default = 9444
}
variable "bootstrap_admin_email" {
  type    = string
  default = "admin@platform.local"
}
variable "environment" { type = string }
variable "run_as_user" {
  description = "Container user. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = ""
}
