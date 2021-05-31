output "storage_account_primary_web_endpoint" {
  description = "The storage account's self-hosted static site URL"
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}

output "azure_function_defualt_url" {
  description = "The storage account's default DNS entry"
  value       = "https://${azurerm_function_app.static_site.default_hostname}"
}

output "azure_functions_service_principal" {
  value = data.azuread_service_principal.azure_functions_system_managed_identity
}


output "azure_functions_system_identity_principal_id" {
  value = azurerm_function_app.static_site.identity.0.principal_id
}

# output "debug" {
#   value = azurerm_function_app.static_site
# }