variable "name" {
  type        = string
  description = "Slug is added to the name of most resources"
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
  type = map(any)
  default = {
    "ManagedBy" = "Terraform"
  }
}

variable "custom_dns" {
  description = "Informaiton required to "
  type = object({
    dns_provider               = string
    dns_id                     = string
    lets_encrypt_contact_email = string
  })

  validation {
    condition = (var.custom_dns == null
    || (var.custom_dns == null ? "azure" : var.custom_dns.dns_provider) == "azure")
    error_message = "Custom DNS provider for terraform-azurerm-static-site only supports Azure DNS."
  }

  default = null
}
