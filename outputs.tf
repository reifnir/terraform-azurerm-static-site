output "storage_account_primary_web_endpoint" {
  description = "The storage account's self-hosted static site URL"
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}

output "azure_function_defualt_url" {
  description = "The Azure Functions application's default URL"
  value       = "https://${local.default_hostname}"
}

output "custom_dns_domains" {
  description = "List of any custom DNS domains that were created bound to the static site"
  value       = local.subject_alternative_names
}
