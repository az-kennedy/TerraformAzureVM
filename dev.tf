terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

# BEGIN AND SETUP
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "dev" {
  name     = "rg-AzureVMs"
  location = "eastus"

  tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }
}

# Build out the network
module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.dev.name
  address_spaces      = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["Sub1", "Sub2", "Sub3", "Sub4"]

  tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }

  depends_on = [azurerm_resource_group.dev]
}

output "vnet_id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the newly created vNet"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  description = "The location of the newly created vNet"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_address_space" {
  description = "The address space of the newly created vNet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "vnet_subnets" {
  description = "The ids of subnets created inside the newly created vNet"
  value       = azurerm_subnet.subnet.*.id
}

# Build the VMs
resource "azurerm_public_ip" "dev" {
   name                         = "publicIPForLB"
   location                     = azurerm_resource_group.dev.location
   resource_group_name          = azurerm_resource_group.dev.name
   allocation_method            = "Static"

   tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }
 }

resource "azurerm_network_interface" "dev" {
  count               = 2
  name                = "vmlinuxrh2022${count.index}"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.subnet.1.id
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }
}

resource "azurerm_managed_disk" "dev" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.dev.location
  resource_group_name  = azurerm_resource_group.dev.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "256"
  
  tags = {
   "Terraform"   : "true"
   "Environment" : "dev"
  }
}

resource "azurerm_availability_set" "dev" {
  name                         = "avset"
  location                     = azurerm_resource_group.dev.location
  resource_group_name          = azurerm_resource_group.dev.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true

  tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }
}

resource "azurerm_virtual_machine" "dev" {
  count                 = 2
  name                  = "acctvm${count.index}"
  location              = azurerm_resource_group.dev.location
  availability_set_id   = azurerm_availability_set.dev.id
  resource_group_name   = azurerm_resource_group.dev.name
  network_interface_ids = [element(azurerm_network_interface.dev.*.id, count.index)]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.4"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = element(azurerm_managed_disk.dev.*.name, count.index)
    managed_disk_id = element(azurerm_managed_disk.dev.*.id, count.index)
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = element(azurerm_managed_disk.dev.*.disk_size_gb, count.index)
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    "Terraform"   : "true"
    "Environment" : "dev"
  }
}