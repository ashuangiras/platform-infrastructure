variable "network_name" { type = string }
variable "pg_data_path" { type = string }
variable "pg_superuser_password" {
  type      = string
  sensitive = true
}
variable "pg_authentik_password" {
  type      = string
  sensitive = true
}
variable "redis_data_path" { type = string }
variable "redis_config_path" { type = string }
variable "redis_admin_password" {
  type      = string
  sensitive = true
}
variable "redis_authentik_password" {
  type      = string
  sensitive = true
}
variable "environment" { type = string }
variable "run_as_user" {
  description = "Container user. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = ""
}
