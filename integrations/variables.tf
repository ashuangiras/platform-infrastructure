# ── Service endpoints ────────────────────────────────────────────────────────

variable "vault_addr" {
  description = "Vault API address reachable from the host."
  type        = string
  default     = "http://localhost:8200"
}

variable "vault_token" {
  description = "Vault root token. Set via VAULT_TOKEN env var in deploy.sh."
  type        = string
  sensitive   = true
}

variable "authentik_url" {
  description = "Authentik HTTP URL reachable from the host."
  type        = string
  default     = "http://localhost:9080"
}

variable "authentik_token" {
  description = "Authentik bootstrap API token (AUTHENTIK_BOOTSTRAP_TOKEN)."
  type        = string
  sensitive   = true
}

variable "minio_endpoint" {
  description = "MinIO S3 endpoint reachable from the host."
  type        = string
  default     = "http://localhost:9000"
}

variable "minio_root_user" {
  description = "MinIO root (admin) username."
  type        = string
}

variable "minio_root_password" {
  description = "MinIO root (admin) password."
  type        = string
  sensitive   = true
}

# ── PostgreSQL credentials ───────────────────────────────────────────────────

variable "pg_superuser_password" {
  description = "PostgreSQL superuser password. Written to Vault."
  type        = string
  sensitive   = true
}

variable "pg_host" {
  description = "PostgreSQL host (Docker network hostname)."
  type        = string
}

variable "pg_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "pg_databases" {
  description = "Map of PostgreSQL database names → {user, password}. Written to Vault per-database."
  type = map(object({
    user     = string
    password = string
  }))
  sensitive = true
}

# ── Redis credentials ────────────────────────────────────────────────────────

variable "redis_host" {
  description = "Redis host (Docker network hostname)."
  type        = string
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "redis_admin_password" {
  description = "Redis default (admin) user password. Written to Vault."
  type        = string
  sensitive   = true
}

variable "redis_users" {
  description = "Map of Redis ACL usernames → {password}. Written to Vault per-user."
  type = map(object({
    password = string
  }))
  sensitive = true
}

# ── Authentik credentials ────────────────────────────────────────────────────

variable "authentik_admin_email" {
  description = "Authentik bootstrap admin email."
  type        = string
  default     = "admin@platform.local"
}

variable "authentik_admin_password" {
  description = "Authentik bootstrap admin password. Written to Vault."
  type        = string
  sensitive   = true
}

variable "authentik_secret_key" {
  description = "Authentik SECRET_KEY. Written to Vault."
  type        = string
  sensitive   = true
}

# ── Authentik internal URL (used by services on Docker network) ───────────────

variable "authentik_internal_url" {
  description = "Authentik URL reachable from containers (Docker network). Used as OIDC issuer."
  type        = string
  default     = "http://platform-authentik-server:9000"
}

# ── Environment ──────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment label."
  type        = string
}
