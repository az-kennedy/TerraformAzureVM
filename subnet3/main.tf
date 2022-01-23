resource "azurerm_network_interface" "sub3" {
  name                 = "vmrhsub3"
  location             = var.location
  resource_group_name  = var.resource_group_name

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