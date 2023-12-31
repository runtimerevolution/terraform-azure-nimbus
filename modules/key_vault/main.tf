resource "azurerm_key_vault" "key_vault" {
  name                       = "${var.solution_name}-key-vault"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = var.environment == "Production" ? 30 : 7
  sku_name                   = "standard"

  access_policy {
    tenant_id           = data.azurerm_client_config.current.tenant_id
    object_id           = data.azurerm_client_config.current.object_id
    key_permissions     = ["Get", "Create"]
    secret_permissions  = ["Get", "Set"]
    storage_permissions = ["Get", "Set"]
  }
}
