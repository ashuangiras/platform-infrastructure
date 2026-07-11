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

## State backend (ADR-0014)

The Terraform state is stored in MinIO (self-hosted S3-compatible storage), providing versioned, lockable state without external cloud dependency.

### Initial setup

1. Copy the backend config template and fill in MinIO credentials:
   ```bash
   cp backend.hcl.example backend.hcl
   # Edit backend.hcl — set access_key and secret_key
   ```

2. Create the state bucket in MinIO (after MinIO is running):
   ```bash
   mc alias set local http://localhost:9000 <root-user> <root-password>
   mc mb local/platform-terraform-state
   mc version enable local/platform-terraform-state
   ```

3. Initialise Terraform with the backend config:
   ```bash
   terraform init -backend-config=backend.hcl
   ```

4. If migrating from a previous local state file:
   ```bash
   terraform init -migrate-state -backend-config=backend.hcl
   ```

**`backend.hcl` is in `.gitignore`** — never commit it. After creating the MinIO access key, store it in Vault.

## Compliance

Every PR runs the 7-job compliance gate. Include `terraform plan` output in the PR description to satisfy IAC-002 (plan-before-apply).
