terraform {
  # Bumping required version now that we're using the nonsensitive function
  required_version = ">= 0.15"

  required_providers {
    # default_hostname and custom_domain_verification_id weren't implemented until v3.14.0
    azurerm = {
      version = ">= 3.14.0"
    }
    acme = {
      # Since this isn't a Hashicorp-specific provider, not implicitly trusting patches
      source  = "vancluever/acme"
      version = "2.13.1"
    }
  }
}
