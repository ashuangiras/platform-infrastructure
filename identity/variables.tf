variable "network_name" { type = string }
variable "secret_key" {
  type      = string
  sensitive = true
}
variable "database_url" {
  type      = string
  sensitive = true
}
variable "redis_url" {
  type      = string
  sensitive = true
}
variable "bootstrap_admin_password" {
  type      = string
  sensitive = true
}
variable "http_port" {
  type    = number
  default = 9000
}
variable "https_port" {
  type    = number
  default = 9443
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
