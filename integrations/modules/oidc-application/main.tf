resource "authentik_provider_oauth2" "this" {
  name               = var.slug
  client_id          = var.slug
  authorization_flow = var.authorization_flow_id
  invalidation_flow  = var.invalidation_flow_id

  allowed_redirect_uris = var.allowed_redirect_uris

  access_code_validity  = var.access_code_validity
  access_token_validity = var.access_token_validity

  property_mappings = var.property_mapping_ids

  # Flow IDs and property mapping IDs are derived from data sources that are
  # deferred to apply time (due to depends_on on the parent module). The values
  # don't change after creation; ignore drift from the re-read data sources.
  lifecycle {
    ignore_changes = [authorization_flow, invalidation_flow, property_mappings]
  }
}

resource "authentik_application" "this" {
  name              = var.name
  slug              = var.slug
  protocol_provider = authentik_provider_oauth2.this.id
  meta_icon         = var.meta_icon != "" ? var.meta_icon : null
  meta_description  = var.description

  policy_engine_mode = "any"
}
