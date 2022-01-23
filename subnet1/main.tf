resource "azurerm_network_interface" "sub1" {
  count                = 2
  name                 = "vmrhsub1-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name

  ip_configuration {
    name                          = "sub1Configuration"
    subnet_id                     = var.vnet_subnets.0
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    "Terraform" : "true"
    "Subnet" : "1"
  }
}

resource "azurerm_managed_disk" "sub1" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "256"

  tags = {
    "Terraform" : "true"
    "Subnet" : "1"
  }
}

resource "azurerm_availability_set" "sub1" {
  name                         = "avset"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true

  tags = {
    "Terraform" : "true"
    "Subnet" : "1"
  }
}

resource "azurerm_virtual_machine" "dev" {
  count                            = 2
  name                             = "vmdev-${count.index}"
  location                         = var.location
  availability_set_id              = azurerm_availability_set.sub1.id
  resource_group_name              = var.resource_group_name
  network_interface_ids            = [element(azurerm_network_interface.sub1.*.id, count.index)]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.4"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = element(azurerm_managed_disk.sub1.*.name, count.index)
    managed_disk_id = element(azurerm_managed_disk.sub1.*.id, count.index)
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = element(azurerm_managed_disk.sub1.*.disk_size_gb, count.index)
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
    "Subnet" : "1"
  }
}

resource "azurerm_network_security_group" "sub1" {
  name                = "sg-sub1"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.vnet_address_space.0
    destination_address_prefix = "*"
  }

  tags = {
    "Terraform" : "true"
    "Subnet" : "1"
  }
}

resource "azurerm_subnet_network_security_group_association" "sub1" {
  count = 4
  subnet_id                 = element(var.vnet_subnets.*, count.index)
  network_security_group_id = azurerm_network_security_group.sub1.id
}