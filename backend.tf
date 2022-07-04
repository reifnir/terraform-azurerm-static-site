terraform {
  required_version = ">= 0.14"

  required_providers {
    azurerm = {
      # Only testing with azurerm provider 2, need to test before being used in 3
      version = ">= 3"
    }
    acme = {
      # Since this isn't a Hashicorp-specific provider, not implicitly trusting patches
      source  = "vancluever/acme"
      version = "2.9.0"
    }
  }
}
