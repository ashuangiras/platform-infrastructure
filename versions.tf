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
provider "vault" {
  address         = var.vault_addr
  token           = var.vault_token
  skip_tls_verify = true
}

provider "authentik" {
  url      = var.authentik_url
  token    = var.authentik_bootstrap_token
  insecure = true
}

provider "null" {}
