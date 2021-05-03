terraform {
  required_version = "~> 0.14"
  required_providers {
    azurerm = {
      # Only testing with azurerm provider 2, need to test before being used in 3
      version = "~> 2"
    }
  }
}

provider "azurerm" {
  features {}
}

module "file_extensions" {
  source  = "reifnir/mime-map/null"
  version = "1.0.0"
}

locals {
  resource_group_name       = "rg-${var.name}-static-function"
  name_without_special_char = replace(var.name, "/[^\\w]*/", "")

  # Storage account names constraints:
  #   contain numbers and lowercase letters
  #   be from 3 to 24 characters long ("sa" + max of 14 characters from name + 8 random == 24)
  #   must be unique across all storage accounts as they are given a unique public DNS name
  storage_account_name_slug = substr(lower(local.name_without_special_char), 0, 14)
  storage_account_name      = "sa${local.storage_account_name_slug}${random_string.storage_account_name.result}"
  specified_404_page = length(tostring(var.error_404_document)) > 0 ? true : false

  function_package_container_name = "${var.name}-static-site-az-fn-packages"

  now          = timestamp()
  now_friendly = formatdate("YYYY-MM-DD-hh-mm-ss", local.now)
  in_ten_years = "${(tonumber(formatdate("YYYY", local.now)) + 10)}-${formatdate("MM-DD'T'hh:mm:ssZ", local.now)}"

  content_type_map = module.file_extensions.mappings
}

resource "azurerm_resource_group" "static_site" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}
