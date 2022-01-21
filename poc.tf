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



resource "azurerm_public_ip" "dev" {
   name                         = "publicIPForLB"
   location                     = azurerm_resource_group.dev.location
   resource_group_name          = azurerm_resource_group.dev.name
   allocation_method            = "Static"
 }

resource "azurerm_lb" "dev" {
  name                = "loadBalancer"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.dev.id
  }
}

resource "azurerm_lb_backend_address_pool" "dev" {
  loadbalancer_id     = azurerm_lb.dev.id
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "dev" {
  count               = 2
  name                = "acctni${count.index}"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = network.vnet_subnets.Sub2.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_availability_set" "dev" {
  name                         = "avset"
  location                     = azurerm_resource_group.dev.location
  resource_group_name          = azurerm_resource_group.dev.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
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