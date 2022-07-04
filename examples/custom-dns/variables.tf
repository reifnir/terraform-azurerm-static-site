variable "azure_dns_zone_id" {
  description = "Azure identifier for the DNS zone in which we'll be creating records."
  type        = string
}

variable "azure_client_id" {
  description = "This value is passed into the ACME provider in order to perform the ACME DNS verification in order to generate a valid TLS certificate."
  type        = string
}

variable "azure_client_secret" {
  description = "This value is passed into the ACME provider in order to perform the ACME DNS verification in order to generate a valid TLS certificate."
  type        = string
}
