resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "jump-server-ssh-private-key"
  value        = tls_private_key.jump_server.private_key_pem
  key_vault_id = var.key_vault_id
}
