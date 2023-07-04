resource "azurerm_subnet" "bastion_vm" {
  name                 = "${var.solution_name}-subnet-bastion"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 3)]
}

resource "azurerm_public_ip" "bastion_host" {
  name                = "${var.solution_name}-bastion-pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion" {
  name                = "${var.solution_name}-nic-bastion"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "bastion-nic"
    subnet_id                     = azurerm_subnet.bastion_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_host.id
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.solution_name}-bastion-inbound"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "${var.solution_name}-bastion-inbound-rule"
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

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                            = "${var.solution_name}-bastion"
  admin_username                  = "adminuser"
  admin_password                  = "Password123?"
  disable_password_authentication = false
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  size                            = "Standard_DS1_v2"

  network_interface_ids = [azurerm_network_interface.bastion.id]

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
}
