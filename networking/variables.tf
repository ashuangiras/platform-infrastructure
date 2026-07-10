variable "subnet" {
  description = "CIDR block for the platform Docker network."
  type        = string
}

variable "gateway" {
  description = "Gateway IP for the platform Docker network."
  type        = string
}

variable "environment" {
  description = "Environment label applied to all resources."
  type        = string
}
