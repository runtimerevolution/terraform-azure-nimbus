locals {
  static_website_origin = var.enable_static_website ? {
    sa = {
      name                = "sa"
      host_name           = var.storage_account_web_host
      forwarding_protocol = "HttpsOnly"
      patterns_to_match   = ["/*"]
    }
  } : {}

  application_gateway_origin = var.enable_application ? {
    ag = {
      name                = "ag"
      host_name           = var.application_gateway_public_ip_address
      forwarding_protocol = "HttpOnly"
      patterns_to_match   = var.cdn_application_patterns_to_match
    }
  } : {}

  origins = merge(local.static_website_origin, local.application_gateway_origin)
}

resource "azurerm_cdn_frontdoor_profile" "frontdoor" {
  name                = "${var.solution_name}-frontdoor"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.solution_name}-frontdoor-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
}

module "route" {
  for_each = local.origins

  source = "../azure_cdn_route"

  solution_name             = var.solution_name
  origin_name               = each.key
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.frontdoor.id
  origin_host_name          = each.value.host_name
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
  route_forwarding_protocol = each.value.forwarding_protocol
  route_patterns_to_match   = each.value.patterns_to_match
}

# Create an Azure DNS Zone
resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
}

# Create a CNAME record to map the domain to the CDN Endpoint hostname
# The domain will be re-routed to the Azure CDN
resource "azurerm_dns_cname_record" "cdn_cname_record" {
  name                = var.cdn_cname_record_name
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_dns_zone.dns_zone.resource_group_name
  ttl                 = 300  
  record              = azurerm_cdn_frontdoor_endpoint.endpoint.host_name   # CDN endpoint hostname
}