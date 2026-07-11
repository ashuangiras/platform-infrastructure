# integrations — wires all running platform services after deployment.
#
# This directory is split into focused files:
#   vault-credentials.tf   — KV v2 engine + all service credential writes
#   authentik-identity.tf  — groups, users, OIDC apps, scope mappings
#   vault-oidc-auth.tf     — Vault JWT/OIDC auth backend, policies, roles
#   minio-oidc.tf          — MinIO identity provider configuration (mc CLI)
#   versions.tf            — required_providers declarations
#   variables.tf           — all input variables
#   outputs.tf             — exported values
#
# Deployment: called from root main.tf with depends_on=[module.secrets, ...]
# deploy.sh handles the two-phase apply that ensures services are healthy first.
