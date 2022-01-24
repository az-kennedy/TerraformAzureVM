# Create Load Balancer
resource "azurerm_lb" "lb" {
  name                = "LoadBalancer"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = var.lb_public_ip_id
  }

  tags = {
    "Terraform" : "true"
    "loadbalancer" : "true"
  }
}

# Create backend pool
resource "azurerm_lb_backend_address_pool" "lb" {
  name            = "loadbalancer_bk_end_pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_backend_address_pool_address" "lb" {
  name                    = "loadbalancer_ip"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb.id
  virtual_network_id      = var.vnet_id
  ip_address              = var.vm_sub3_ip
}

resource "azurerm_lb_probe" "lb" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "http-running-probe"
  port                = 80
}

resource "azurerm_lb_rule" "lb" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  enable_tcp_reset               = "true"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb.id]
  probe_id                       = azurerm_lb_probe.lb.id
  disable_outbound_snat          = "true"
}