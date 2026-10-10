output "image_reference" {
  description = "Marketplace image reference used by the Azure Windows VMs."
  value       = module.vm.image_reference
}

output "vm_ids" {
  description = "IDs of the Azure Windows VMs."
  value       = module.vm.vm_ids
}

output "vm_names" {
  description = "Names of the Azure Windows VMs."
  value       = module.vm.vm_names
}

output "private_ip_addresses" {
  description = "Private IP addresses of the Azure Windows VMs."
  value       = module.vm.private_ip_addresses
}

output "public_ip_addresses" {
  description = "Public IP addresses of the Azure Windows VMs."
  value       = module.vm.public_ip_addresses
}

output "resource_group_name" {
  description = "Resource group name used by the Azure resources."
  value       = module.vm.resource_group_name
}

output "virtual_network_id" {
  description = "ID of the module-created virtual network, or null when using existing networking."
  value       = module.vm.virtual_network_id
}

output "subnet_id" {
  description = "ID of the module-created subnet, or the global existing subnet ID."
  value       = module.vm.subnet_id
}

output "network_security_group_id" {
  description = "ID of the module-created network security group, or the global existing network security group ID."
  value       = module.vm.network_security_group_id
}
