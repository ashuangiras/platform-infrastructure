terraform {
  required_version = "~> 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # State backend — starts with local for bootstrap.
  # After MinIO is running, migrate with:
  #   terraform init -migrate-state -backend-config=backend-minio.hcl
  # See README.md for the full migration procedure.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {
  # Uses the local Docker socket by default (/var/run/docker.sock).
  # Override with DOCKER_HOST env var if the Docker daemon is remote.
}
