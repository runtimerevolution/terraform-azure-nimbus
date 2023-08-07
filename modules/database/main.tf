# -----------------------------------------------------------------------------
# Database servers
# -----------------------------------------------------------------------------
resource "azurerm_mssql_server" "server" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  administrator_login          = var.server_administrator_login
  administrator_login_password = var.server_administrator_login_password
  version                      = var.server_version
  connection_policy            = "Proxy"
}

# -----------------------------------------------------------------------------
# Allow Azure services and resources to access the SQL server
# -----------------------------------------------------------------------------
resource "azurerm_mssql_firewall_rule" "server" {
  name             = "${var.server_name}-allow-azure-rule"
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
resource "azurerm_mssql_database" "database" {
  for_each = { for i, db in var.server_databases : i => db }

  name                                = coalesce(each.value.name, "${var.server_name}-db-${each.key + 1}")
  server_id                           = azurerm_mssql_server.server.id
  collation                           = coalesce(each.value.collation, "SQL_Latin1_General_CP1_CI_AS")
  license_type                        = coalesce(each.value.license_type, "LicenseIncluded")
  maintenance_configuration_name      = coalesce(each.value.maintenance_configuration_name, "SQL_Default")
  max_size_gb                         = coalesce(each.value.max_size_gb, 2)
  sku_name                            = coalesce(each.value.sku_name, "Basic")
  storage_account_type                = coalesce(each.value.storage_account_type, "Geo")
  transparent_data_encryption_enabled = coalesce(each.value.transparent_data_encryption_enabled, true)
}

resource "azurerm_mssql_virtual_network_rule" "server_private_subnet_rule" {
  name      = "${azurerm_mssql_server.server.name}-private-subnet-rule"
  server_id = azurerm_mssql_server.server.id
  subnet_id = var.private_subnet_id
}
