variable "solution_name" {
  type        = string
  description = "Name of the solution."
}

variable "enable_static_website" {
  type        = bool
  description = "Enables/disables serving a static website hosted in a Storage Account."
}

variable "enable_application" {
  type        = bool
  description = "Enables/disables serving application(s) using Container Apps to host containers."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to host the CDN."
}

variable "resource_group_location" {
  type        = string
  description = "The Azure location where to create the resources."
}

variable "storage_account_web_host" {
  type        = string
  description = "Host name for the Storage Account hosting the static website."
}

variable "application_gateway_public_ip_address" {
  type        = string
  description = "IP address of the application gateway."
}

variable "cdn_application_patterns_to_match" {
  type        = list(string)
  description = "The path patterns to redirect to the application gateway."
}

variable "dns_zone_name" {
  type        = string
  description = "Domain name"
}

variable "cdn_cname_record_name" {
  type        = string
  description = "Subdomain to use"
  default     = "www"
}
