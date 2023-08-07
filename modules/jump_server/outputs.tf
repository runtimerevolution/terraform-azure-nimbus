output "jump_server_public_ip_address" {
  value = azurerm_public_ip.jump_server.ip_address
}

output "jump_server_ssh_private_key" {
  value     = tls_private_key.jump_server.private_key_pem
  sensitive = true
}
