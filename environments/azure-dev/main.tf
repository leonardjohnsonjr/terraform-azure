module "vm" {
  source = "../../modules/azure_vm"

  site_name      = var.site_name
  environment    = var.environment
  app_short_name = var.app_short_name
  location       = var.location

  create_resource_group = var.create_resource_group
  resource_group_name   = var.resource_group_name

  create_network            = var.create_network
  vnet_address_space        = var.vnet_address_space
  subnet_address_prefix     = var.subnet_address_prefix
  allowed_rdp_cidr          = var.allowed_rdp_cidr
  subnet_id                 = var.subnet_id
  network_security_group_id = var.network_security_group_id
  admin_username            = var.admin_username
  admin_password            = var.admin_password
  tags                      = var.tags
  azure_vm_roles            = var.azure_vm_roles
}
