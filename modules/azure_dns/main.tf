# Only create DNS resources if enable_dns is true
resource "azurerm_dns_zone" "dns_zone" {
  count               = var.enable_dns ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_cname_record" "cdn_cname_record" {
  count               = var.enable_dns ? 1 : 0
  name                = var.cdn_cname_record_name
  zone_name           = var.enable_dns ? azurerm_dns_zone.dns_zone[0].name : ""
  resource_group_name = var.enable_dns ? azurerm_dns_zone.dns_zone[0].resource_group_name : ""
  ttl                 = 300  
  record              = var.enable_dns ? var.cdn_frontdoor_endpoint_host_name : ""  # CDN endpoint hostname
}