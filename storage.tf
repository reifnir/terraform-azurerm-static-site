resource "random_string" "storage_account_name" {
  lower   = true
  number  = true
  upper   = false
  special = false
  length  = 8
}

resource "azurerm_storage_account" "static_site" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.static_site.name
  location                 = azurerm_resource_group.static_site.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Use the static_website section without the error_404_document populated when there is a value in var.error_404_document
  dynamic "static_website" {
    for_each = local.specified_404_page ? [1] : []
    content {
      index_document     = var.index_document
      error_404_document = var.error_404_document
    }
  }

  # Use the static_website section without the error_404_document populated when there's no value in var.error_404_document
  dynamic "static_website" {
    for_each = local.specified_404_page ? [] : [1]
    content {
      index_document     = var.index_document
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "function_packages" {
  name                  = local.function_package_container_name
  storage_account_name  = azurerm_storage_account.static_site.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "static_files" {
  for_each               = fileset(var.static_content_directory, "**")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.static_site.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = local.content_type_map[split(".", each.value)[length(split(".", each.value)) - 1]]
  source                 = "${var.static_content_directory}/${each.value}"
}
