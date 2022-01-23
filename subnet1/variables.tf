variable "resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "location" {
  type        = string
  description = "location of resource group"
}

variable "vnet_subnets" {
  type        = list(string)
  description = "list of subnets"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "address space of vnet"
}

variable "vm_public_ip" {
  type        = string
  description = "Public IP of the VM"
}
