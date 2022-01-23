terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

# Setup
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-AzureVMs"
  location = "eastus"

  tags = {
    "Terraform" : "true"
  }
}

# Build out the network
module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  address_spaces      = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["Sub1", "Sub2", "Sub3", "Sub4"]

  tags = {
    "Terraform" : "true"
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_public_ip" "lb" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "lbGateway" {
  name                = "PublicIPForGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Infrastructure for Subnet 1
module "subnet1" {
  source              = "./subnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnets        = module.network.vnet_subnets
  vnet_address_space  = module.network.vnet_address_space

}

# Create Infrastructure for Subnet 3
module "subnet3" {
  source              = "./subnet3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnets        = module.network.vnet_subnets
  vnet_address_space  = module.network.vnet_address_space
  lb_ip_address       = azurerm_public_ip.lb.ip_address 
}

# Load Balancer Code and NAT Gateway
resource "azurerm_lb" "lb" {
  name                = "LoadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb" {
  name            = "loadbalancer_bk_end_pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_backend_address_pool_address" "lb" {
  name                    = "loadbalancer_ip"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb.id
  virtual_network_id      = module.network.vnet_id
  ip_address              = module.subnet3.ip
}

resource "azurerm_lb_rule" "lb" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  enable_tcp_reset               = "true"
}

resource "azurerm_lb_nat_rule" "lb" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "myNATRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_nat_gateway" "lb" {
  name                = "lb-NatGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_subnet_nat_gateway_association" "lb" {
  subnet_id      = module.network.vnet_subnets.2
  nat_gateway_id = azurerm_nat_gateway.lb.id
}

resource "azurerm_nat_gateway_public_ip_association" "lb" {
  nat_gateway_id       = azurerm_nat_gateway.lb.id
  public_ip_address_id = azurerm_public_ip.lbGateway.id
}