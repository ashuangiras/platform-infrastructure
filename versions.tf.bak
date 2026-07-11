terraform {
  required_version = "~> 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # S3-compatible backend pointing at the self-hosted MinIO instance.
  # Values are supplied at init time via backend.hcl (never committed — in .gitignore).
  #
  # Bootstrap procedure (one time):
  #   1. On first deploy, run: terraform init -backend-config=backend.hcl
  #   2. Copy backend.hcl.example to backend.hcl and fill in MinIO credentials
  #   3. If migrating from a previous local state: terraform init -migrate-state -backend-config=backend.hcl
  #
  # See README.md → "State backend" for full instructions (ADR-0014).
  backend "s3" {}
}

provider "docker" {
  # Uses the local Docker socket by default (/var/run/docker.sock).
  # Override with DOCKER_HOST env var if the Docker daemon is remote.
}
