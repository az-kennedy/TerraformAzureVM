output "ip" {
  value       = azurerm_network_interface.sub3.private_ip_address
  description = "The IP address of the vm instance on subnet 3"
}