variable "name" {
  type        = string
  description = "Slug is added to the name of most resources. This is also the name of the Azure Functions application and MUST be unique across all of Azure."
}

variable "location" {
  type        = string
  description = "Azure region in which resources will be located"
  default     = "eastus"
}

variable "static_content_directory" {
  type        = string
  description = "This is the path to the directory containing static resources."
}

variable "enable_app_insights" {
  type        = bool
  description = "App Insights isn't free. If you don't want App Insights attached to this site, set this value to false. You can always enable it later if you need to troubleshoot something."
  default     = false
}

variable "index_document" {
  type        = string
  description = "The webpage that Azure Storage serves for requests to the root of a website or any subfolder. For example, index.html. The value is case-sensitive."
  default     = "index.html"
}

variable "error_404_document" {
  type        = string
  description = "The absolute path to a custom webpage that should be used when a request is made which does not correspond to an existing file."
  default     = ""
}

variable "tags" {
  type = map(string)
  default = {
    "ManagedBy" = "Terraform"
  }
}

variable "custom_dns" {
  description = "Information required to wire-up custom DNS for your static site. When setting hostnames, be sure to enter the full DNS. Note that the Azure client secret is necessary for completing ACME DNS verification when generating a Let's Encrypt TLS certificate."
  type = object({
    dns_provider               = string
    dns_zone_id                = string
    hostnames                  = set(string)
    lets_encrypt_contact_email = string
    azure_client_id            = string
    azure_client_secret        = string
  })

  validation {
    condition = (
      var.custom_dns == null
      || (var.custom_dns == null ? "azure" : var.custom_dns.dns_provider) == "azure"
    )
    error_message = "Custom DNS provider for terraform-azurerm-static-site only supports Azure DNS. Set this value to 'azure' when setting custom DNS unless you want to add an issue or contribute here: https://github.com/reifnir/terraform-azurerm-static-site/issues."
  }

  validation {
    condition = (
      var.custom_dns == null
      || (var.custom_dns == null ? 9 : length(split("/", var.custom_dns.dns_zone_id))) == 9
    )
    error_message = "Variable custom_dns.dns_zone_id must be the full Azure DNS Zone id. Ex: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-my-resource-group/providers/Microsoft.Network/dnszones/example.com'."
  }

  default = null
}
