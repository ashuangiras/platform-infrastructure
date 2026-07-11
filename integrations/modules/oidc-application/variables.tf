variable "name" {
  description = "Human-readable application name shown in the Authentik UI."
  type        = string
}

variable "slug" {
  description = "URL-safe application slug (also used as client_id)."
  type        = string
}

variable "description" {
  description = "Application description shown in the Authentik UI."
  type        = string
  default     = ""
}

variable "meta_icon" {
  description = "URL to the application icon. Optional."
  type        = string
  default     = ""
}

variable "allowed_redirect_uris" {
  description = "List of allowed redirect URIs. Each entry: {matching_mode, url}."
  type = list(object({
    matching_mode = string
    url           = string
  }))
}

variable "authorization_flow_id" {
  description = "Authentik authorization flow ID."
  type        = string
}

variable "invalidation_flow_id" {
  description = "Authentik invalidation flow ID."
  type        = string
}

variable "property_mapping_ids" {
  description = "List of Authentik scope property mapping IDs (openid, email, profile)."
  type        = list(string)
}

variable "access_code_validity" {
  description = "OAuth2 authorization code validity duration."
  type        = string
  default     = "minutes=1"
}

variable "access_token_validity" {
  description = "OAuth2 access token validity duration."
  type        = string
  default     = "hours=1"
}
