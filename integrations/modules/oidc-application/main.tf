resource "authentik_provider_oauth2" "this" {
  name               = var.slug
  client_id          = var.slug
  authorization_flow = var.authorization_flow_id
  invalidation_flow  = var.invalidation_flow_id

  allowed_redirect_uris = var.allowed_redirect_uris

  access_code_validity  = var.access_code_validity
  access_token_validity = var.access_token_validity

  property_mappings = var.property_mapping_ids
}

resource "authentik_application" "this" {
  name              = var.name
  slug              = var.slug
  protocol_provider = authentik_provider_oauth2.this.id
  meta_icon         = var.meta_icon != "" ? var.meta_icon : null
  meta_description  = var.description

  policy_engine_mode = "any"
}
