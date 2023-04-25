output "VM-IP" {
  description = "The VM Public IP is:"
  value       = azurerm_public_ip.my_terraform_public_ip.public_ip_prefix_id
}


output "VM-Name" {
  description = "The VM Name is:"
  value       = azurerm_windows_virtual_machine.main.name
}