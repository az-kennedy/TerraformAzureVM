variable "resource_group_name" {
  type        = string
  description = "name of resource group"
}

variable "location" {
  type        = string
  description = "location of resource group"
}

variable "lb_public_ip_id" {
  type        = string
  description = "public ip of load blanacer"
}

variable "vnet_id" {
  type        = string
  description = "vnet id"
}

variable "vm_sub3_ip" {
  type        = string
  description = "ip of vm instance in subnet 3"
}