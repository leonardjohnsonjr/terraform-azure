terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : var.resource_group_name

  role_instances = flatten([
    for role_name, role in var.azure_vm_roles : [
      for index in range(role.instance_count) : {
        key                          = "${role_name}-${index + 1}"
        name                         = format("%s-%s-%s-%s%02d", var.site_name, var.environment, var.app_short_name, role_name, index + 1)
        role_name                    = role_name
        vm_size                      = role.vm_size
        os_disk_size_gb              = role.os_disk_size_gb
        os_disk_caching              = role.os_disk_caching
        os_disk_storage_account_type = role.os_disk_storage_account_type
        associate_public_ip_address  = role.associate_public_ip_address
        subnet_id                    = role.subnet_id != null ? role.subnet_id : (var.create_network ? azurerm_subnet.subnet[0].id : var.subnet_id)
        network_security_group_id    = role.network_security_group_id != null ? role.network_security_group_id : (var.create_network ? azurerm_network_security_group.rdp[0].id : var.network_security_group_id)
        tags                         = merge(var.tags, role.tags)
      }
    ]
  ])

  instances = {
    for instance in local.role_instances : instance.key => instance
  }

  public_ip_instances = {
    for key, instance in local.instances : key => instance
    if instance.associate_public_ip_address
  }

  image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk-g2"
    version   = "latest"
  }
}

resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

  name     = coalesce(var.resource_group_name, "${var.site_name}-${var.environment}-${var.app_short_name}-rg")
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "virtual_network" {
  count = var.create_network ? 1 : 0

  name                = "${var.site_name}-${var.environment}-${var.app_short_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = local.resource_group_name != null
      error_message = "resource_group_name must be provided when create_resource_group is false."
    }
  }
}

resource "azurerm_subnet" "subnet" {
  count = var.create_network ? 1 : 0

  name                 = "${var.site_name}-${var.environment}-${var.app_short_name}-subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network[0].name
  address_prefixes     = [var.subnet_address_prefix]
}

# Fetch your current public IP address
data "http" "my_ip" {
  url = "https://icanhazip.com"
}


resource "azurerm_network_security_group" "rdp" {
  count = var.create_network ? 1 : 0

  name                = "${var.site_name}-${var.environment}-${var.app_short_name}-rdp-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_rdp_cidr
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-RDP-From-Home"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${chomp(data.http.my_ip.response_body)}/32" 
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "public_ip" {
  for_each = local.public_ip_instances

  name                = "${each.value.name}-pip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = each.value.tags
}

resource "azurerm_network_interface" "network_interface" {
  for_each = local.instances

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = each.value.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.associate_public_ip_address ? azurerm_public_ip.public_ip[each.key].id : null
  }

  lifecycle {
    precondition {
      condition     = local.resource_group_name != null
      error_message = "resource_group_name must be provided when create_resource_group is false."
    }

    precondition {
      condition     = each.value.subnet_id != null
      error_message = "A subnet_id must be provided when create_network is false, either globally or per Azure VM role."
    }
  }
}

resource "azurerm_network_interface_security_group_association" "security_group_association" {
  for_each = local.instances

  network_interface_id      = azurerm_network_interface.network_interface[each.key].id
  network_security_group_id = each.value.network_security_group_id

  lifecycle {
    precondition {
      condition     = each.value.network_security_group_id != null
      error_message = "A network_security_group_id must be provided when create_network is false, either globally or per Azure VM role."
    }
  }
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  for_each = local.instances

  name                = each.value.name
  resource_group_name = local.resource_group_name
  location            = var.location
  size                = each.value.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.network_interface[each.key].id
  ]

  os_disk {
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = local.image_reference.publisher
    offer     = local.image_reference.offer
    sku       = local.image_reference.sku
    version   = local.image_reference.version
  }

  tags = merge(each.value.tags, {
    Name = each.value.name
    Role = each.value.role_name
  })
}
