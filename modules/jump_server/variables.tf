variable "solution_name" {
  type        = string
  description = "Name of the solution."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to host the CDN."
}

variable "resource_group_location" {
  type        = string
  description = "The Azure location where to create the resources."
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network to host the bastion host."
}

variable "vnet_cidr" {
  type        = string
  description = "The IPv4 CIDR address of the virtual network to host the bastion host."
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID to host the VM."
}

variable "enable_key_vault" {
  type        = bool
  description = "Enables/disables key vault to store sensible data as secret."
}

variable "key_vault_id" {
  type        = string
  description = "ID of the key vault to store the SSH private key as a secret."
}
