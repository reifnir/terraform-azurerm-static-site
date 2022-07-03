locals {
  create_dns                   = var.custom_dns != null
  dns_zone_subscription_id     = local.create_dns ? split("/", var.custom_dns.dns_zone_id)[2] : ""
  dns_zone_resource_group_name = local.create_dns ? split("/", var.custom_dns.dns_zone_id)[4] : ""
  dns_zone_name                = local.create_dns ? split("/", var.custom_dns.dns_zone_id)[8] : ""

  # Maps create more meaningful terraform state names than counts (which can cause errors if you re-order the list)
  dns_cname_list     = local.create_dns ? [for h in var.custom_dns.hostnames : h if h != "@"] : []
  dns_cname_map      = { for h in local.dns_cname_list : h => h }
  dns_naked_a_record = local.create_dns ? contains(var.custom_dns.hostnames, "@") : false
}

# data.azurerm_dns_zone.custom.0
data "azurerm_dns_zone" "custom" {
  count               = local.create_dns ? 1 : 0
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_resource_group_name
}

resource "azurerm_dns_cname_record" "cnames_to_function" {
  for_each            = local.dns_cname_map
  name                = each.key
  zone_name           = data.azurerm_dns_zone.custom.0.name
  resource_group_name = data.azurerm_dns_zone.custom.0.resource_group_name
  ttl                 = 60
  record              = local.default_hostname
  tags                = var.tags
}

# need a wait for eventual consistency?
data "dns_a_record_set" "function" {
  host       = local.default_hostname
  depends_on = [azurerm_linux_function_app.static_site]
}

resource "azurerm_dns_a_record" "naked_domain" {
  count               = local.dns_naked_a_record ? 1 : 0
  name                = "@"
  zone_name           = data.azurerm_dns_zone.custom.0.name
  resource_group_name = data.azurerm_dns_zone.custom.0.resource_group_name
  ttl                 = 300
  records             = data.dns_a_record_set.function.addrs
}

resource "azurerm_dns_txt_record" "function_domain_verification" {
  for_each            = local.subject_alternative_names
  name                = each.value.verification_name
  zone_name           = data.azurerm_dns_zone.custom.0.name
  resource_group_name = data.azurerm_dns_zone.custom.0.resource_group_name
  ttl                 = 30

  record {
    value = data.azurerm_function_app.static_site.custom_domain_verification_id
  }

  # This is a race condition, consider adding a script that waits until the expected TXT record can be found
  # If this blows up, just increase the duration or rerun apply
  provisioner "local-exec" {
    command = "sleep 10s"
  }
}

resource "azurerm_app_service_custom_hostname_binding" "static_site" {
  for_each            = local.subject_alternative_names
  hostname            = each.value.full_domain
  app_service_name    = azurerm_linux_function_app.static_site.name
  resource_group_name = azurerm_resource_group.static_site.name
  depends_on          = [azurerm_dns_txt_record.function_domain_verification]
}
