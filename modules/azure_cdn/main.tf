###########################################################################################################
# Defines and creates Azure CDN, Azure Front Door and DNS settings to re-route a domain to the Azure CDN  #
###########################################################################################################

# The "locals" defines conditional settings for the static website origin and application gateway origin
locals {

  # Defines the settings for the static website origin 
  static_website_origin = var.enable_static_website ? {
    sa = {
      name                = "sa"
      host_name           = var.storage_account_web_host
      forwarding_protocol = "HttpsOnly"
      patterns_to_match   = ["/*"]
    }
  } : {}

  # Defines settings for the application gateway origin 
  application_gateway_origin = var.enable_application ? {
    ag = {
      name                = "ag"
      host_name           = var.application_gateway_public_ip_address
      forwarding_protocol = "HttpOnly"
      patterns_to_match   = var.cdn_application_patterns_to_match
    }
  } : {}

  # Merges the static website and application gateway origins to create a combined origins map
  origins = merge(local.static_website_origin, local.application_gateway_origin)
}

# Creates an Azure Front Door profile for routing traffic to the origins
resource "azurerm_cdn_frontdoor_profile" "frontdoor" {
  name                = "${var.solution_name}-frontdoor"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
}

# Creates an Azure Front Door endpoint
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.solution_name}-frontdoor-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor.id
}

# Creates routing rules for each origin using the Azure CDN route module
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

# Include the DNS configuration if enable_dns is true
module "dns" {
  source = "../azure_dns"
  
  enable_dns             = var.enable_dns
  dns_zone_name          = var.dns_zone_name
  cdn_cname_record_name  = var.cdn_cname_record_name
  resource_group_name    = var.resource_group_name
  cdn_frontdoor_endpoint_host_name = azurerm_cdn_frontdoor_endpoint.endpoint.host_name 
}