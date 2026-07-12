terraform {
  required_version = "~> 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2024.8"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # platform-infrastructure uses a local state backend (ADR-0014 + ADR-0020).
  #
  # WHY LOCAL — not MinIO:
  #   This configuration deploys MinIO. Storing the state of what deploys MinIO
  #   inside MinIO itself creates a circular dependency: you can't init the backend
  #   before MinIO exists, and you can't destroy MinIO without losing the state.
  #   The local backend breaks the cycle. State is on the operator's machine only.
  #
  # platform-services uses MinIO (S3 backend) — that's safe because MinIO is
  # already running before platform-services is ever applied.
  #
  # ⚠ NO STATE LOCKING: the local backend does NOT lock state. Concurrent
  #   `terraform apply` runs will corrupt terraform.tfstate. Run ONE apply at a
  #   time. State also contains secrets at rest — deploy.sh chmods it to 0600
  #   and scripts/backup.sh encrypts it before archiving.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  # Uses the local Docker socket by default (/var/run/docker.sock).
  # Override with DOCKER_HOST env var if the Docker daemon is remote.
}

# Root-level provider stubs — actual configuration lives in integrations/versions.tf
# These must be declared here because Terraform requires all child module providers
# to be available at the root level.
#
# TLS cutover is reversible: every TLS-specific setting is gated on var.tls_enabled
# so flipping tls_enabled = false restores today's plaintext behavior EXACTLY.
provider "vault" {
  address         = var.tls_enabled ? "https://127.0.0.1:${var.vault_port}" : var.vault_addr
  token           = var.vault_token
  ca_cert_file    = var.tls_enabled ? local.tls_ca_cert : null
  skip_tls_verify = var.tls_enabled ? false : true
}

provider "authentik" {
  # Authentik terminates TLS on its https port with its OWN bundled self-signed
  # certificate (NOT the platform CA), and redirects http->https. The platform CA
  # therefore cannot verify authentik's cert, so we skip verification for THIS
  # provider only — a documented, localhost-scoped exception (P0-1). All other
  # providers (vault, etc.) verify against the platform CA.
  url      = var.tls_enabled ? "https://127.0.0.1:${var.authentik_https_port}" : var.authentik_url
  token    = var.authentik_bootstrap_token
  insecure = true
}

provider "null" {}
