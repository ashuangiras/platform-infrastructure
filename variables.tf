# ── Host paths ──────────────────────────────────────────────────────────────
# Directories on the host where each service persists data.
# Create these before running terraform apply (see README.md).

variable "minio_data_path" {
  description = "Host path for MinIO data storage. Must exist and be writable by UID 1000."
  type        = string
  default     = "/srv/platform/minio/data"
}

variable "vault_data_path" {
  description = "Host path for Vault data storage. Must exist and be writable by UID 100."
  type        = string
  default     = "/srv/platform/vault/data"
}

variable "vault_config_path" {
  description = "Host path containing vault.hcl. Must exist and contain a valid config before apply."
  type        = string
  default     = "/srv/platform/vault/config"
}

variable "consul_data_path" {
  description = "Host path for Consul data storage. Must exist and be writable by UID 100."
  type        = string
  default     = "/srv/platform/consul/data"
}

variable "consul_config_path" {
  description = "Host path containing consul.hcl. Must exist and contain a valid config before apply."
  type        = string
  default     = "/srv/platform/consul/config"
}

# ── Networking ───────────────────────────────────────────────────────────────

variable "network_subnet" {
  description = "CIDR block for the platform Docker network."
  type        = string
  default     = "10.100.0.0/24"
}

variable "network_gateway" {
  description = "Gateway address for the platform Docker network."
  type        = string
  default     = "10.100.0.1"
}

# ── MinIO ────────────────────────────────────────────────────────────────────

variable "minio_root_user" {
  description = "MinIO root (admin) username. Set via TF_VAR_minio_root_user or a tfvars file."
  type        = string
  sensitive   = true
}

variable "minio_root_password" {
  description = "MinIO root (admin) password, ≥8 characters. Set via TF_VAR_minio_root_password or a tfvars file."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.minio_root_password) >= 8
    error_message = "minio_root_password must be at least 8 characters."
  }
}

# ── Ports (all optional, defaults match each service's standard port) ─────────

variable "minio_api_port" {
  description = "Host port for MinIO S3 API."
  type        = number
  default     = 9000
}

variable "minio_console_port" {
  description = "Host port for MinIO web console."
  type        = number
  default     = 9001
}

variable "vault_port" {
  description = "Host port for Vault API."
  type        = number
  default     = 8200
}

variable "consul_http_port" {
  description = "Host port for Consul HTTP API and UI."
  type        = number
  default     = 8500
}

variable "consul_dns_port" {
  description = "Host port for Consul DNS."
  type        = number
  default     = 8600
}

# ── Environment label ─────────────────────────────────────────────────────────

variable "environment" {
  description = "Environment name applied as a label to all containers and the Docker network."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment must be one of: production, staging, development."
  }
}

# ── macOS Docker Desktop compatibility ────────────────────────────────────────
# These override the module defaults for local staging on macOS.
# Leave unset (or default) for production Linux hosts.

variable "vault_drop_capabilities" {
  description = "Vault Linux capabilities to drop. Set to [] on macOS Docker Desktop."
  type        = list(string)
  default     = ["ALL"]
}

variable "vault_capabilities" {
  description = "Vault Linux capabilities to add. Set to [] on macOS Docker Desktop (IPC_LOCK causes plan loops with kreuzwerker/docker provider)."
  type        = list(string)
  default     = ["IPC_LOCK"]
}

variable "vault_run_as_user" {
  description = "Vault container user. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = "100:1000"
}

variable "vault_keys_path" {
  description = "Path where Vault init output (unseal keys + root token) is stored. Must be outside the repo and never committed to git."
  type        = string
  default     = "~/.platform/vault-keys.json"
}

variable "consul_run_as_user" {
  description = "Consul container user. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = ""
}

# ── Data infrastructure (PostgreSQL + Redis) ──────────────────────────────────
variable "pg_data_path" {
  description = "Host path for PostgreSQL data persistence."
  type        = string
  default     = "/srv/platform/postgresql/data"
}

variable "pg_superuser_password" {
  description = "PostgreSQL superuser password. Written to Vault by integrations/."
  type        = string
  sensitive   = true
}

variable "pg_authentik_password" {
  description = "PostgreSQL password for the authentik database role. Written to Vault."
  type        = string
  sensitive   = true
}

variable "redis_data_path" {
  description = "Host path for Redis data persistence."
  type        = string
  default     = "/srv/platform/redis/data"
}

variable "redis_config_path" {
  description = "Host path for Redis ACL config (users.acl generated by Terraform)."
  type        = string
  default     = "/srv/platform/redis/config"
}

variable "redis_admin_password" {
  description = "Redis admin ACL user password. Written to Vault."
  type        = string
  sensitive   = true
}

variable "redis_authentik_password" {
  description = "Redis ACL password for the authentik user. Written to Vault."
  type        = string
  sensitive   = true
}

variable "data_run_as_user" {
  description = "Container user for data + identity containers. Set to empty string on macOS Docker Desktop."
  type        = string
  default     = ""
}

# ── Identity (Authentik) ──────────────────────────────────────────────────────
variable "authentik_secret_key" {
  description = "Authentik SECRET_KEY (Django signing key, 50+ random chars). Written to Vault."
  type        = string
  sensitive   = true
}

variable "authentik_admin_password" {
  description = "Authentik bootstrap admin password. Written to Vault."
  type        = string
  sensitive   = true
}

variable "authentik_admin_email" {
  description = "Authentik bootstrap admin email."
  type        = string
  default     = "admin@platform.local"
}

variable "authentik_bootstrap_token" {
  description = "Predictable API token set via AUTHENTIK_BOOTSTRAP_TOKEN on first Authentik startup. Used by the goauthentik/authentik Terraform provider to configure OIDC apps without web UI interaction. Treat as a secret."
  type        = string
  sensitive   = true
  default     = ""
}

variable "authentik_http_port" {
  description = "Host port for Authentik HTTP."
  type        = number
  default     = 9080
}

variable "authentik_https_port" {
  description = "Host port for Authentik HTTPS."
  type        = number
  default     = 9444
}

# ── Provider configuration (integrations) ────────────────────────────────────

variable "vault_addr" {
  description = "Vault API address. Used by vault provider and deploy.sh."
  type        = string
  default     = "http://localhost:8200"
}

variable "vault_token" {
  description = "Vault root token. Set by deploy.sh from ~/.platform/vault-keys.json. Do not hardcode."
  type        = string
  sensitive   = true
  default     = ""
}

variable "authentik_url" {
  description = "Authentik URL from the host. Used by authentik provider."
  type        = string
  default     = "http://localhost:9080"
}

variable "vault_logs_path" {
  description = "Host path for Vault audit logs (SEC-014). Leave empty to skip."
  type        = string
  default     = ""
}
