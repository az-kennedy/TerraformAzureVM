resource "azurerm_network_interface" "sub1" {
  count                = 2
  name                 = "vmrhsub1-${count.index}"
  location             = var.location
  resource_group_name  = var.name

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