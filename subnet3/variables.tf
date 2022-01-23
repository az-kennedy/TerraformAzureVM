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
