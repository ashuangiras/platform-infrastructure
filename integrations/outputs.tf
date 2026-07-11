output "vault_kv_mount" {
  description = "Vault KV v2 mount path."
  value       = vault_mount.kv.path
}

output "vault_oidc_path" {
  description = "Vault OIDC/JWT auth backend path."
  value       = vault_jwt_auth_backend.authentik.path
}

output "vault_oidc_accessor" {
  description = "Vault OIDC auth backend accessor (used for group alias binding)."
  value       = vault_jwt_auth_backend.authentik.accessor
}

output "authentik_vault_client_id" {
  description = "Authentik OIDC client ID for Vault."
  value       = module.oidc_vault.client_id
}

output "authentik_minio_client_id" {
  description = "Authentik OIDC client ID for MinIO."
  value       = module.oidc_minio.client_id
}

output "vault_secrets_path" {
  description = "Vault KV v2 path prefix for all platform secrets."
  value       = "${vault_mount.kv.path}/data/platform"
}

output "platform_admins_group_id" {
  description = "Authentik platform-admins group ID."
  value       = authentik_group.groups["platform-admins"].id
}
