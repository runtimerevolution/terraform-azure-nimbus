output "database_server_fqdn" {
  value = azurerm_mssql_server.server.fully_qualified_domain_name
}
