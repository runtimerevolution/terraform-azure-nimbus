resource "azurerm_subnet" "jump_server" {
  name                 = "${var.solution_name}-subnet-jump-server"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 3)]
}

resource "azurerm_public_ip" "jump_server" {
  name                = "${var.solution_name}-jump-server-pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "jump_server" {
  name                = "${var.solution_name}-nic-jump-server"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "jump-server-nic"
    subnet_id                     = azurerm_subnet.jump_server.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump_server.id
  }
}

resource "azurerm_network_security_group" "jump_server" {
  name                = "${var.solution_name}-jump-server-inbound"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "${var.solution_name}-jump-server-inbound-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jump_server" {
  network_interface_id      = azurerm_network_interface.jump_server.id
  network_security_group_id = azurerm_network_security_group.jump_server.id
}


resource "tls_private_key" "jump_server" {
  algorithm = "RSA"
}

resource "azurerm_linux_virtual_machine" "jump_server" {
  name                            = "${var.solution_name}-jump-server"
  admin_username                  = "adminuser"
  disable_password_authentication = true
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  size                            = "Standard_DS1_v2"

  network_interface_ids = [azurerm_network_interface.jump_server.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.jump_server.public_key_openssh
  }
}
