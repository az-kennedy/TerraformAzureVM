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

  subnet_service_endpoints = {
    "Sub1" : ["Microsoft.Storage"], 
    "Sub2" : ["Microsoft.Storage"],
    "Sub3" : ["Microsoft.Storage"],
    "Sub4" : ["Microsoft.Storage"]
  }

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

resource "azurerm_public_ip" "vmsub1_1" {
  name                = "PublicIPForVMSub1-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    "Terraform" : "true"
  }
}

resource "azurerm_public_ip" "vmsub1_2" {
  name                = "PublicIPForVMSub1-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    "Terraform" : "true"
  }
}

# Create Infrastructure for Subnet 1
module "subnet1" {
  source              = "./subnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnets        = module.network.vnet_subnets
  vnet_address_space  = module.network.vnet_address_space
  vm_public_ip_ids    = [azurerm_public_ip.vmsub1_1.id, azurerm_public_ip.vmsub1_2.id]

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

# Create the Load Balancer
module "loadbalancer" {
  source              = "./loadbalancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  lb_public_ip_id     = azurerm_public_ip.lb.id
  vnet_id             = module.network.vnet_id
  vm_sub3_ip          = module.subnet3.vm_sub3_ip

}


# Create the Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "mystorageaccount01232022"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = module.network.vnet_subnets
  }

  tags = {
    "Terraform" : "true"
  }
}

output "Public_Load_Balancer_IP" {
  value       = azurerm_public_ip.lb.ip_address
  description = "Public IP of the load balancer"
}

output "Public_VM_IPS_Subnet1" {
  value       = [azurerm_public_ip.vmsub1_1.ip_address, azurerm_public_ip.vmsub1_2.ip_address]
  description = "Public IP of the load balancer"
}