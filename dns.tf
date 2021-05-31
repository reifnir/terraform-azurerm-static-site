locals {
  create_dns  = var.custom_dns != null
  dns_entry_count = local.create_dns ? length(var.custom_dns.hostnames) : 0
  dns_entry_list  = local.create_dns ? tolist(var.custom_dns.hostnames) : []

  dns_zone_name                = local.create_dns ? split("/", var.custom_dns.dns_zone_id)[8] : ""
  dns_zone_resource_group_name = local.create_dns ? split("/", var.custom_dns.dns_zone_id)[4] : ""
}

# data.azurerm_dns_zone.custom.0
data "azurerm_dns_zone" "custom" {
  count               = local.create_dns ? 1 : 0
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_resource_group_name
}

resource "azurerm_dns_cname_record" "cnames_to_function" {
  count               = local.dns_entry_count
  name                = local.dns_entry_list[count.index]
  zone_name           = data.azurerm_dns_zone.custom.0.name
  resource_group_name = data.azurerm_dns_zone.custom.0.resource_group_name
  ttl                 = 300
  record              = azurerm_function_app.static_site.default_hostname
  tags                = var.tags
}


output "debug" {
  value = azurerm_dns_cname_record.cnames_to_function
}
