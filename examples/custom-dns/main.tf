terraform {
  # Switch this out for whatever backend you wish to use
  backend "azurerm" {
    resource_group_name  = "rg-common-storage"
    storage_account_name = "sareifnircommonstorage"
    container_name       = "terraform-state"
    key                  = "terraform-azurerm-static-site-custom-dns.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "azure_client_id" {
  description = "This value is passed into the ACME provider in order to perform the ACME DNS verification in order to generate a valid TLS certificate."
}

variable "azure_client_secret" {
  description = "This value is passed into the ACME provider in order to perform the ACME DNS verification in order to generate a valid TLS certificate."
}


resource "random_string" "name_suffix" {
  length  = 4
  number  = true
  lower   = true
  upper   = false
  special = false
}

locals {
  azure_function_name = "static-site-example-custom-dns-${random_string.name_suffix.result}"

  tags = {
    "Application" = "Simple example static site with a custom DNS entry and TLS"
    "ManagedBy"   = "Terraform"
  }
}

# Magic up the static site...
module "custom_dns_static_site" {
  source                   = "../../"
  name                     = local.azure_function_name
  static_content_directory = "${path.root}/static-content"
  error_404_document       = "error_404.html"

  custom_dns = {
    # @ is interpreted as a naked domain. Ex: reifnir.com
    hostnames                  = ["@", "www", "custom-dns-static-site"]
    dns_provider               = "azure"
    dns_zone_id                = "/subscriptions/8df18e1b-269a-426f-a321-ca437966c787/resourceGroups/rg-dns-zones/providers/Microsoft.Network/dnszones/reifnir.com"
    lets_encrypt_contact_email = "jim.andreasen@reifnir.com"
    azure_client_id            = var.azure_client_id
    azure_client_secret        = var.azure_client_secret
  }

  tags = local.tags
}

output "static_site" {
  value = module.custom_dns_static_site
}
