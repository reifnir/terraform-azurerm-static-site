resource "azurerm_service_plan" "static_site" {
  name                = "asp-${var.name}"
  location            = azurerm_resource_group.static_site.location
  resource_group_name = azurerm_resource_group.static_site.name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

data "azurerm_storage_account_sas" "package" {
  connection_string = azurerm_storage_account.static_site.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = local.now
  expiry = local.in_one_hundred_years

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

resource "azurerm_linux_function_app" "static_site" {
  name                       = var.name
  location                   = azurerm_resource_group.static_site.location
  resource_group_name        = azurerm_resource_group.static_site.name
  service_plan_id            = azurerm_service_plan.static_site.id
  storage_account_name       = azurerm_storage_account.static_site.name
  storage_account_access_key = azurerm_storage_account.static_site.primary_access_key
  # Apparently proxies.json isn't supported anymore on runtimes 4 and higher
  # https://docs.microsoft.com/en-us/azure/azure-functions/functions-proxies
  functions_extension_version = "~3"
  https_only                  = true
  builtin_logging_enabled     = false

  site_config {
    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = local.function_package_get_url
    "sha1"                     = data.archive_file.azure_function_package.output_sha
    "sha256"                   = data.archive_file.azure_function_package.output_base64sha256
    "md5"                      = data.archive_file.azure_function_package.output_md5
  }

  tags = var.tags

  depends_on = [
    azurerm_storage_blob.function,
    data.archive_file.azure_function_package
  ]
}
