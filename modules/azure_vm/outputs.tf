output "image_reference" {
  description = "Marketplace image reference used by the Azure Windows VMs."
  value       = local.image_reference
}

output "vm_ids" {
  description = "IDs of the created Azure Windows VMs."
  value       = { for key, vm in azurerm_windows_virtual_machine.windows_vm : key => vm.id }
}

output "vm_names" {
  description = "Names of the created Azure Windows VMs."
  value       = { for key, vm in azurerm_windows_virtual_machine.windows_vm : key => vm.name }
}

output "private_ip_addresses" {
  description = "Private IP addresses of the created Azure VM NICs."
  value       = { for key, nic in azurerm_network_interface.network_interface : key => nic.private_ip_address }
}

output "public_ip_addresses" {
  description = "Public IP addresses of the created Azure public IP resources."
  value       = { for key, public_ip in azurerm_public_ip.public_ip : key => public_ip.ip_address }
}

output "resource_group_name" {
  description = "Resource group name used by the Azure resources."
  value       = local.resource_group_name
}

output "virtual_network_id" {
  description = "ID of the module-created virtual network, or null when using existing networking."
  value       = var.create_network ? azurerm_virtual_network.virtual_network[0].id : null
}

output "subnet_id" {
  description = "ID of the module-created subnet, or the global existing subnet ID."
  value       = var.create_network ? azurerm_subnet.subnet[0].id : var.subnet_id
}

output "network_security_group_id" {
  description = "ID of the module-created network security group, or the global existing network security group ID."
  value       = var.create_network ? azurerm_network_security_group.rdp[0].id : var.network_security_group_id
}
