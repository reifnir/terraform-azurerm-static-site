provider "acme" {
  # You cannot attach a let's encrypt staging cert to an app in Azure, you get a BadRequest 04038 error: Expired certificate is not allowed.
  # So, we only use the production ACME endpoint.
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

locals {
  full_custom_domain_name = local.dns_naked_a_record ? data.azurerm_dns_zone.custom.0.name : (local.create_dns ? "${local.dns_cname_list[0]}.${data.azurerm_dns_zone.custom.0.name}" : "")
  hostnames = { for h in var.custom_dns.hostnames : h =>
    {
      hostname          = h
      full_domain       = h == "@" ? data.azurerm_dns_zone.custom.0.name : "${h}.${data.azurerm_dns_zone.custom.0.name}"
      verification_name = h == "@" ? "asuid" : "asuid.${h}"
    }
  }
  subject_alternative_names = [for x in local.hostnames : x.full_domain]
}

resource "tls_private_key" "reg_private_key" {
  count     = local.create_dns ? 1 : 0
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count           = local.create_dns ? 1 : 0
  account_key_pem = tls_private_key.reg_private_key.0.private_key_pem
  email_address   = var.custom_dns.lets_encrypt_contact_email
}

resource "random_password" "pfx" {
  count  = local.create_dns ? 1 : 0
  length = 16
}

resource "acme_certificate" "certificate" {
  count                     = local.create_dns ? 1 : 0
  account_key_pem           = acme_registration.reg.0.account_key_pem
  key_type                  = "4096"
  common_name               = local.full_custom_domain_name
  subject_alternative_names = local.subject_alternative_names
  certificate_p12_password  = random_password.pfx.0.result
  min_days_remaining        = 30

  dns_challenge {
    provider = "azure"

    config = {
      AZURE_CLIENT_ID       = var.custom_dns.azure_client_id
      AZURE_CLIENT_SECRET   = var.custom_dns.azure_client_secret
      AZURE_SUBSCRIPTION_ID = local.dns_zone_subscription_id
      AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
      AZURE_ENVIRONMENT     = "public"
      AZURE_RESOURCE_GROUP  = local.dns_zone_resource_group_name
    }
  }
  depends_on = [azurerm_dns_txt_record.function_domain_verification]
}

resource "azurerm_app_service_certificate" "custom_hostname" {
  count               = local.create_dns ? 1 : 0
  name                = local.subject_alternative_names.0
  resource_group_name = azurerm_resource_group.static_site.name
  location            = azurerm_resource_group.static_site.location
  pfx_blob            = acme_certificate.certificate.0.certificate_p12
  password            = acme_certificate.certificate.0.certificate_p12_password
  depends_on          = [acme_certificate.certificate]
}

resource "azurerm_app_service_certificate_binding" "custom_hostname" {
  for_each            = local.hostnames
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.static_site[each.key].id
  certificate_id      = azurerm_app_service_certificate.custom_hostname.0.id
  ssl_state           = "SniEnabled"
}

data "azurerm_client_config" "current" {
}
