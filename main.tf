# -----------------------------------------------------------------------------
# Resource Group to contain the solution resources
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "resource_group" {
  name     = var.solution_name
  location = var.location
}

# -----------------------------------------------------------------------------
# Key Vault to store secrets
# -----------------------------------------------------------------------------
module "key_vault" {
  count = var.enable_key_vault ? 1 : 0

  source = "./modules/key_vault"

  solution_name           = var.solution_name
  environment             = var.environment
  resource_group_name     = azurerm_resource_group.resource_group.name
  resource_group_location = azurerm_resource_group.resource_group.location
}

# -----------------------------------------------------------------------------
# Static website
# -----------------------------------------------------------------------------
module "static_website" {
  count = var.enable_static_website ? 1 : 0

  source = "./modules/storage_account"

  solution_name                    = var.solution_name
  resource_group_name              = azurerm_resource_group.resource_group.name
  resource_group_location          = azurerm_resource_group.resource_group.location
  storage_account_kind             = "StorageV2"
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"
  static_website_settings = {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}

# -----------------------------------------------------------------------------
# Virtual network and subnets
# -----------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  solution_name           = var.solution_name
  resource_group_name     = azurerm_resource_group.resource_group.name
  resource_group_location = azurerm_resource_group.resource_group.location
  vnet_cidr               = var.vnet_cidr
}

# -----------------------------------------------------------------------------
# Container Apps
# -----------------------------------------------------------------------------
module "container_app_environment" {
  count = var.enable_application ? 1 : 0

  source = "./modules/container_app_environment"

  solution_name           = var.solution_name
  resource_group_name     = azurerm_resource_group.resource_group.name
  resource_group_location = azurerm_resource_group.resource_group.location
  private_subnet_id       = module.network.private_subnet_id
  containers              = var.containers
}

# -----------------------------------------------------------------------------
# Application Gateway
# -----------------------------------------------------------------------------
module "application_gateway" {
  count = var.enable_application ? 1 : 0

  source = "./modules/application_gateway"

  solution_name                               = var.solution_name
  resource_group_name                         = azurerm_resource_group.resource_group.name
  resource_group_location                     = azurerm_resource_group.resource_group.location
  public_subnet_id                            = module.network.public_subnet_id
  container_app_environment_static_ip_address = module.container_app_environment[0].container_app_environment_static_ip_address
  container_apps                              = module.container_app_environment[0].container_apps
}

# -----------------------------------------------------------------------------
# CDN
# -----------------------------------------------------------------------------
module "cdn" {
  count = var.enable_static_website || var.enable_application ? 1 : 0

  source = "./modules/azure_cdn"

  solution_name                         = var.solution_name
  enable_static_website                 = var.enable_static_website
  enable_application                    = var.enable_application
  resource_group_name                   = azurerm_resource_group.resource_group.name
  resource_group_location               = azurerm_resource_group.resource_group.location
  storage_account_web_host              = var.enable_static_website ? module.static_website[0].storage_account_web_host : null
  application_gateway_public_ip_address = var.enable_application ? module.application_gateway[0].application_gateway_public_ip_address : null
  cdn_application_patterns_to_match     = var.cdn_application_patterns_to_match
  dns_zone_name                         = var.dns_zone_name

  depends_on = [module.application_gateway]
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
module "databases" {
  for_each = { for i, ds in var.database_servers : i => ds }

  source = "./modules/database"

  solution_name                       = var.solution_name
  resource_group_name                 = azurerm_resource_group.resource_group.name
  resource_group_location             = azurerm_resource_group.resource_group.location
  server_name                         = coalesce(each.value.name, "${var.solution_name}-db-server-${each.key + 1}")
  server_administrator_login          = coalesce(each.value.administrator_login, "${var.solution_name}_admin")
  server_administrator_login_password = coalesce(each.value.administrator_login_password, "passw0rd?")
  server_version                      = coalesce(each.value.version, "12.0")
  server_databases                    = coalesce(each.value.databases, [{}])
  private_subnet_id                   = module.network.private_subnet_id
  enable_key_vault                    = var.enable_key_vault
  key_vault_id                        = module.key_vault[0].key_vault_id
}

module "jump_server" {
  count = var.enable_jump_server ? 1 : 0

  source = "./modules/jump_server"

  solution_name           = var.solution_name
  resource_group_name     = azurerm_resource_group.resource_group.name
  resource_group_location = azurerm_resource_group.resource_group.location
  vnet_name               = module.network.vnet_name
  vnet_cidr               = var.vnet_cidr
  public_subnet_id        = module.network.public_subnet_id
  enable_key_vault        = var.enable_key_vault
  key_vault_id            = module.key_vault[0].key_vault_id
}
