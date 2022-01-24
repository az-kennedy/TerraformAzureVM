resource "azurerm_network_interface" "sub3" {
  name                = "vmrhsub3"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "sub3Configuration"
    subnet_id                     = var.vnet_subnets.2
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    "Terraform" : "true"
    "Subnet" : "3"
  }
}

resource "azurerm_managed_disk" "sub3" {
  name                 = "datadisk_existing_sub3"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "32"

  tags = {
    "Terraform" : "true"
    "Subnet" : "3"
  }
}

resource "azurerm_virtual_machine" "sub3" {
  name                             = "vmrhsub3"
  location                         = var.location
  resource_group_name              = var.resource_group_name
  network_interface_ids            = [azurerm_network_interface.sub3.id]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk-sub3"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = azurerm_managed_disk.sub3.name
    managed_disk_id = azurerm_managed_disk.sub3.id
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = azurerm_managed_disk.sub3.disk_size_gb
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
    "Terraform" : "true"
    "Subnet" : "3"
  }
}

resource "azurerm_virtual_machine_extension" "sub3" {
  name                 = "apacheInstall"
  virtual_machine_id   = azurerm_virtual_machine.sub3.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/thomaskennedy1066/TerraformAzureVM/main/apache.sh" ],
        "commandToExecute": "bash apache.sh exit 0"
    }
  SETTINGS

  tags = {
    "Terraform" : "true"
    "Subnet" : "3"
  }
}

resource "azurerm_network_security_group" "sub3" {
  name                = "sg-sub3"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowHttp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowLoadBalancer"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.lb_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInternal"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_address_space.0
    destination_address_prefix = "*"
  }

  tags = {
    "Terraform" : "true"
    "Subnet" : "3"
  }
}

resource "azurerm_subnet_network_security_group_association" "sub3" {
  subnet_id                 = var.vnet_subnets.2
  network_security_group_id = azurerm_network_security_group.sub3.id
}