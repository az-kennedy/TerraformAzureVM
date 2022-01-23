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

  tags = {
    "Terraform" : "true"
  }
}

/*
resource "azurerm_public_ip" "lbGateway" {
  name                = "PublicIPForGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
*/

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


module "loadbalancer" {
  source              = "./loadbalancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  lb_public_ip_id     = azurerm_public_ip.lb.id
  vnet_id             = module.network.vnet_id
  vm_sub3_ip          = module.subnet3.vm_sub3_ip

}
