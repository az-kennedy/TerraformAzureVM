resource "azurerm_network_interface" "sub2" {
  name                 = "vmrhsub2"
  location             = var.location
  resource_group_name  = var.resource_group_name

  ip_configuration {
    name                          = "sub1Configuration"
    subnet_id                     = var.vnet_subnets.2
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    "Terraform" : "true"
    "Subnet" : "2"
  }
}