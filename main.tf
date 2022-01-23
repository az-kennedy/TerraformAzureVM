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

module "subnet1" {
  source              = "./subnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnets        = module.network.vnet_subnets
  vnet_address_space  = module.network.vnet_address_space

}

module "subnet3" {
  source              = "./subnet3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnets        = module.network.vnet_subnets
}