terraform {
  # Switch this out for whatever backend you wish to use
  backend "azurerm" {
    resource_group_name  = "rg-common-storage"
    storage_account_name = "sareifnircommonstorage"
    container_name       = "terraform-state"
    key                  = "terraform-azurerm-azure-functions-static-site-some-custom-dns.tfstate"
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
  # Hostname is the part of the DNS record that comes before the domain and TLD. See: https://techterms.com/definition/fqdn
  #   Ex: hostname.mydomain.com       -> hostname = 'hostname'
  #   Ex: other.hostname.mydomain.com -> hostname = 'other.hostname'
  # We want to host our static site at 'some-custom-dns-0000.somedomain.com'
  dns_hostname                 = "some-custom-dns-${random_string.name_suffix.result}"
  # full_custom_domain_name      = "${local.dns_hostname}.${data.azurerm_dns_zone.custom.name}"
  # dns_zone_subscription_id     = split("/", var.azure_dns_zone_id)[2]
  # dns_zone_name                = split("/", var.azure_dns_zone_id)[8]
  # dns_zone_resource_group_name = split("/", var.azure_dns_zone_id)[4]

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

output "debug" {
  value = module.simple_example_static_site
  sensitive = true
}
