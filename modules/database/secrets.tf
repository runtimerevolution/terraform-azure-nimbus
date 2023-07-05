resource "azurerm_key_vault_secret" "db_server_credentials" {
  count = var.enable_key_vault ? 1 : 0
   
  name = "${azurerm_mssql_server.server.name}-credentials"
  value = jsonencode({
    username = azurerm_mssql_server.server.administrator_login
    password = azurerm_mssql_server.server.administrator_login_password
  })
  key_vault_id = var.key_vault_id
}
