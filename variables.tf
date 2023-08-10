variable "solution_name" {
  type        = string
  description = "Name of the solution."
}

variable "environment" {
  type        = string
  description = "Application environment type."
  default     = "Staging"

  validation {
    condition     = contains(["Staging", "Production"], var.environment)
    error_message = "Invalid value. Expected 'Staging' or 'Production'."
  }
}

variable "location" {
  type        = string
  description = "Location where resources must be created."
  default     = "eastus"
}

variable "enable_static_website" {
  type        = bool
  description = "Enables/disables serving a static website hosted in a Storage Account."
  default     = false
}

variable "enable_application" {
  type        = bool
  description = "Enables/disables serving application(s) using Container Apps to host containers."
  default     = false
}

variable "static_website_settings" {
  type = object({
    index_document     = string
    error_404_document = string
  })
  description = "Static website settings."
  default = {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}

variable "cdn_application_patterns_to_match" {
  type        = list(string)
  description = "The path patterns to redirect to the application gateway."
  default     = ["/*"]
}

variable "vnet_cidr" {
  type        = string
  description = "The IPv4 CIDR address for the virtual network."
  default     = "10.0.0.0/16"
}

variable "containers" {
  type = list(object({
    name         = string
    image        = string
    cpu          = number
    memory       = string
    port         = number
    min_replicas = optional(number)
    max_replicas = optional(number)
  }))
  description = "Container instances to be deployed."
  default     = []
}

variable "database_servers" {
  type = list(
    object({
      name                         = optional(string)
      administrator_login          = optional(string)
      administrator_login_password = optional(string)
      version                      = optional(string)
      databases = optional(
        list(object({
          name                                = optional(string)
          collation                           = optional(string)
          license_type                        = optional(string)
          maintenance_configuration_name      = optional(string)
          max_size_gb                         = optional(number)
          sku_name                            = optional(string)
          storage_account_type                = optional(string)
          transparent_data_encryption_enabled = optional(bool)
          })
        )
      )
    })
  )
  description = "Database servers and instances to deploy."
  default     = []
}

variable "enable_jump_server" {
  type        = bool
  description = "Enables/disables jump server for establishing a SSH tunnel to access resources in private subnets."
  default     = false
}

variable "enable_key_vault" {
  type        = bool
  description = "Enables/disables key vault to store sensible data as secret."
  default     = false
}

variable "enable_dns" {
  type        = bool
  description = "Enables/disables DNS."
  default     = false
}

variable "dns_zone_name" {
  type        = string
  description = "Domain name"
}