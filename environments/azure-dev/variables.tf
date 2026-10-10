variable "location" {
  description = "Azure region where resources will be created."
  type        = string
  default     = "eastus"
}

variable "site_name" {
  description = "Site code used in the Azure VM naming convention."
  type        = string
}

variable "environment" {
  description = "Environment code used in the Azure VM naming convention."
  type        = string
  default     = "dev"
}

variable "app_short_name" {
  description = "Short application or workload name used in the Azure VM naming convention."
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a resource group for the Azure VM resources."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name to create or use for Azure VM resources."
  type        = string
  default     = null
}

variable "create_network" {
  description = "Whether to create a VNet, subnet, network security group, public IPs, and NICs."
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "Address space for the module-created virtual network."
  type        = string
  default     = "10.60.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the module-created subnet."
  type        = string
  default     = "10.60.1.0/24"
}

variable "allowed_rdp_cidr" {
  description = "CIDR block allowed to connect to RDP when create_network is true."
  type        = string
  default     = "203.0.113.10/32"
}

variable "subnet_id" {
  description = "Existing subnet ID used when create_network is false and a role does not override it."
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "Existing network security group ID used when create_network is false and a role does not override it."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Local administrator username for Windows VMs."
  type        = string
}

variable "admin_password" {
  description = "Local administrator password for Windows VMs."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "admin_password must be at least 12 characters."
  }
}

variable "tags" {
  description = "Tags applied to all Azure resources created by this environment."
  type        = map(string)
  default     = {}
}

variable "azure_vm_roles" {
  description = "Map of Azure VM roles to VM settings."
  type = map(object({
    instance_count               = number
    vm_size                      = optional(string, "Standard_D2s_v3")
    os_disk_size_gb              = optional(number, 128)
    os_disk_caching              = optional(string, "ReadWrite")
    os_disk_storage_account_type = optional(string, "StandardSSD_LRS")
    associate_public_ip_address  = optional(bool, true)
    subnet_id                    = optional(string)
    network_security_group_id    = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {}
}
