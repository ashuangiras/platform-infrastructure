terraform {
  required_version = "~> 1.9"

  required_providers {
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
}

# Provider configuration is inherited from the root module (versions.tf).
# Do NOT add provider blocks here — that would make this a "legacy" module
# and would block the caller from using depends_on.
