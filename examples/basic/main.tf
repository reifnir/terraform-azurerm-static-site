terraform {
  # Switch this out for whatever backend you wish to use
  backend "azurerm" {
    resource_group_name  = "rg-common-storage"
    storage_account_name = "sareifnircommonstorage"
    container_name       = "terraform-state"
    key                  = "terraform-azurerm-static-site.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "name_suffix" {
  length  = 4
  number  = true
  lower   = true
  upper   = false
  special = false
}

locals {
  azure_function_name = "static-site-example-${random_string.name_suffix.result}"

  tags = {
    "Application" = "Simple example static site with a custom DNS entry and TLS"
    "ManagedBy"   = "Terraform"
  }
}

# Magic up the static site...
module "simple_example_static_site" {
  source                   = "../../"
  name                     = local.azure_function_name
  static_content_directory = "${path.root}/static-content"
  error_404_document       = "error_404.html"
  tags                     = local.tags
}

output "static_site" {
  value = module.simple_example_static_site
}
