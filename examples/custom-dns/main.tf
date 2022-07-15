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

resource "random_string" "name_suffix" {
  length  = 4
  numeric = true
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
    # @ is interpreted as a naked domain. Ex: decomposingsoftware.com
    hostnames                  = ["@", "www", "deeper.subdomain"]
    dns_provider               = "azure"
    dns_zone_id                = var.azure_dns_zone_id
    lets_encrypt_contact_email = "jim.andreasen@reifnir.com"
    azure_client_id            = var.azure_client_id
    azure_client_secret        = var.azure_client_secret
  }

  tags = local.tags
}

output "static_site" {
  value = module.custom_dns_static_site
}
