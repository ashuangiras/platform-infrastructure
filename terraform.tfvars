# Staging environment — macOS local host (PC-0139)
# Data paths use ~/platform-data/ (macOS-compatible; /srv/ requires root)

minio_data_path    = "/Users/angirasa/platform-data/minio/data"
vault_data_path    = "/Users/angirasa/platform-data/vault/data"
vault_config_path  = "/Users/angirasa/platform-data/vault/config"
consul_data_path   = "/Users/angirasa/platform-data/consul/data"
consul_config_path = "/Users/angirasa/platform-data/consul/config"

minio_root_user     = "platform-admin"
minio_root_password = "platform-admin-secret"

environment = "staging"

# macOS Docker Desktop compatibility overrides
vault_drop_capabilities = []
vault_capabilities      = []
vault_run_as_user       = ""
vault_keys_path         = "/Users/angirasa/.platform/vault-keys.json"
consul_run_as_user      = ""

# Data infrastructure
pg_data_path             = "/Users/angirasa/platform-data/postgresql/data"
pg_superuser_password    = "pg-superuser-staging"
pg_authentik_password    = "pg-authentik-staging"
redis_data_path          = "/Users/angirasa/platform-data/redis/data"
redis_config_path        = "/Users/angirasa/platform-data/redis/config"
redis_admin_password     = "redis-admin-staging"
redis_authentik_password = "redis-authentik-staging"

# Identity (Authentik)
authentik_secret_key      = "staging-secret-key-please-change-this-to-50plus-random-chars"
authentik_admin_password  = "admin-staging"
authentik_bootstrap_token = "platform-bootstrap-token-staging"
authentik_http_port       = 9080
authentik_https_port      = 9444
