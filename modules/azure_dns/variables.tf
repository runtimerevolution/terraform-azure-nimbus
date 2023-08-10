variable "cdn_frontdoor_endpoint_host_name" {
  type        = string
  description = "host_name of the CDN Front Door endpoint"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to host the CDN."
}

variable "enable_dns" {
  type        = bool
  description = "Enables/disables DNS."
  default     = false
}

variable "dns_zone_name" {
  type        = string
  description = "Domain name."
}

variable "cdn_cname_record_name" {
  type        = string
  description = "Subdomain to use"
  default     = "www"
}
