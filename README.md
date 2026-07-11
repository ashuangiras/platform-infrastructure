# platform-infrastructure

Root Terraform configuration for the self-hosted platform. Deploys Vault, Consul, and MinIO as Docker containers using modules from [platform-modules](https://github.com/ashuangiras/platform-modules).

Governed by [platform-compliance](https://github.com/ashuangiras/platform-compliance) at profile [`PROF-TERRAFORM-ROOT-V1`](https://github.com/ashuangiras/platform-compliance/blob/main/04-profiles/PROF-TERRAFORM-ROOT-V1.yaml).

## What this deploys

```
Docker network: platform-backend (10.100.0.0/24)
      │
      ├── MinIO  (S3-compatible storage — ADR-0014)   :9000 (API), :9001 (console)
      ├── Vault  (secret management    — ADR-0008)    :8200 (API)
      └── Consul (config + discovery   — ADR-0019)    :8500 (HTTP), :8600 (DNS)
```

All services run as non-root users with pinned image tags. No cloud provider required.

## Prerequisites

### 1. Docker
Docker must be installed and running on the target host.

### 2. Terraform ≥ 1.9

### 3. Host directories
```bash
sudo mkdir -p /srv/platform/{minio/data,vault/{data,config},consul/{data,config}}
sudo chown -R 1000:1000 /srv/platform/minio/data
sudo chown -R 100:1000  /srv/platform/vault/data /srv/platform/vault/config
sudo chown -R 100:1000  /srv/platform/consul/data /srv/platform/consul/config
```

### 4. Vault config — `/srv/platform/vault/config/vault.hcl`
```hcl
storage "file" { path = "/vault/data" }
listener "tcp"  { address = "0.0.0.0:8200"; tls_disable = true }
ui           = true
api_addr     = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"
```

### 5. Consul config — `/srv/platform/consul/config/consul.hcl`
```hcl
datacenter = "platform-dc1"
data_dir   = "/consul/data"
ui_config { enabled = true }
```

## First deploy

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set minio_root_user and minio_root_password

terraform init
terraform plan -out=tfplan   # review before applying (IAC-002)
terraform apply tfplan
```

## Vault initialisation (first time only)

```bash
export VAULT_ADDR=http://localhost:8200
vault operator init
# Store unseal keys and root token securely — never commit them
vault operator unseal  # run 3 times with different unseal keys
```

## State migration to MinIO (PC-0138)

Once MinIO is running, create the state bucket then:
```bash
# Create backend-minio.hcl (see outputs.state_migration_backend_config for the content)
terraform init -migrate-state -backend-config=backend-minio.hcl
```
Update `versions.tf` to use the `s3` backend, commit, and re-init.

## Compliance

Every PR runs the 7-job compliance gate. Include `terraform plan` output in the PR description to satisfy IAC-002 (plan-before-apply).
