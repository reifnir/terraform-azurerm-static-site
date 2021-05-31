resource "azurerm_app_service_plan" "static_site" {
  name                = "asp-${var.name}"
  location            = azurerm_resource_group.static_site.location
  resource_group_name = azurerm_resource_group.static_site.name
  kind                = "FunctionApp" # You might think this should be Linux...
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = var.tags
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
  }
}

resource "azurerm_function_app" "static_site" {
  name                       = var.name
  location                   = azurerm_resource_group.static_site.location
  resource_group_name        = azurerm_resource_group.static_site.name
  app_service_plan_id        = azurerm_app_service_plan.static_site.id
  storage_account_name       = azurerm_storage_account.static_site.name
  storage_account_access_key = azurerm_storage_account.static_site.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true
  enable_builtin_logging     = false

  site_config {
    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = local.function_package_get_url
    # "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.static_site.0.instrumentation_key : ""

    # Informational
    "package_creation_timestamp" = local.now
    "sha1"                       = data.archive_file.azure_function_package.output_sha
    "sha256"                     = data.archive_file.azure_function_package.output_base64sha256
    "md5"                        = data.archive_file.azure_function_package.output_md5
  }

  tags = var.tags

  depends_on = [
    azurerm_storage_blob.function,
    data.archive_file.azure_function_package
  ]
}
