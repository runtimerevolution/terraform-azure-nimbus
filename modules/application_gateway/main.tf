#################################################################################
#         This section defines and creates an Azure Application Gateway         #
#################################################################################

# The "locals" block defines reusable variables within the module
locals {
  backend_address_pool_name      = "${var.solution_name}-beap"
  frontend_ip_configuration_name = "${var.solution_name}-feip"
}

# Creates a public IP resource for the Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.solution_name}-app-gateway-pip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Creates an Azure Application Gateway resource
resource "azurerm_application_gateway" "app_gateway" {
  name                = "${var.solution_name}-app-gateway"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }

  # Configures the gateway IP using the public IP
  gateway_ip_configuration {
    name      = "${var.solution_name}-gateway-ip-config"
    subnet_id = var.public_subnet_id
  }

  # Dynamically creates the frontend ports
  dynamic "frontend_port" {
    for_each = var.container_apps

    content {
      name = "${frontend_port.value.name}-feport"
      port = frontend_port.value.port
    }
  }

  # Configures the frontend IP using the public IP
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  # Configures the backend address pool
  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [var.container_app_environment_static_ip_address]
  }

  # Dynamically creates the backend HTTP settings
  dynamic "backend_http_settings" {
    for_each = var.container_apps

    content {
      name                  = "${backend_http_settings.value.name}-be-htst"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = backend_http_settings.value.port
      protocol              = "Http"
      request_timeout       = 60
      host_name             = backend_http_settings.value.fqdn
      probe_name            = "${backend_http_settings.value.name}-probe"
    }
  }

  # Creates probes for each container application
  dynamic "probe" {
    for_each = var.container_apps

    content {
      host                = probe.value.fqdn
      name                = "${probe.value.name}-probe"
      protocol            = "Http"
      path                = "/"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3

      match {
        status_code = ["200"]
      }
    }
  }

  # Creates HTTP listeners for each container application
  dynamic "http_listener" {
    for_each = var.container_apps

    content {
      name                           = "${http_listener.value.name}-httplstn"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = "${http_listener.value.name}-feport"
      protocol                       = "Http"
    }
  }

  # Creates request routing rules for each container application
  dynamic "request_routing_rule" {
    for_each = var.container_apps

    content {
      name                       = "${request_routing_rule.value.name}-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.value.name}-httplstn"
      backend_address_pool_name  = local.backend_address_pool_name
      backend_http_settings_name = "${request_routing_rule.value.name}-be-htst"
      priority                   = 1
    }
  }
}
