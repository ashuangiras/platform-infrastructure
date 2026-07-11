output "authentik_http_url" {
  description = "Authentik HTTP URL from the host."
  value       = module.authentik.http_url
}

output "authentik_issuer_url" {
  description = "OIDC issuer URL — use as oidc_discovery_url in Vault JWT auth and Grafana OAuth2."
  value       = module.authentik.issuer_url
}

output "authentik_internal_url" {
  description = "Authentik URL from containers on the Docker network."
  value       = module.authentik.internal_url
}
