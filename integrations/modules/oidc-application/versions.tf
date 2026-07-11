terraform {
  required_version = "~> 1.9"
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2024.8"
    }
  }
}
# Provider configuration inherited from root — do not add provider blocks here.
