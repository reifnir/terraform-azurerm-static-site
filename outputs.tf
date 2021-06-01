output "storage_account_primary_web_endpoint" {
  description = "The storage account's self-hosted static site URL"
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}

output "azure_function_defualt_url" {
  description = "The storage account's default DNS entry"
  value       = "https://${azurerm_function_app.static_site.default_hostname}"
}

output "dns_entries" {
  value = local.subject_alternative_names
}