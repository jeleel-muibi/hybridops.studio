
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.110.0" }
  }
}
provider "azurerm" { features {} }
resource "azurerm_resource_group" "rg" {
  name = "${var.prefix}-rg"
  location = var.location
  tags = var.tags
}
resource "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}-vnet"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = [var.vnet_cidr]
  tags = var.tags
}
resource "azurerm_subnet" "subnet" {
  name = "${var.prefix}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [var.subnet_cidr]
}
resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip ? 1 : 0
  name = "${var.prefix}-pip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"
  sku = "Basic"
  tags = var.tags
}
resource "azurerm_network_interface" "nic" {
  name = "${var.prefix}-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "ipcfg"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.create_public_ip ? azurerm_public_ip.pip[0].id : null
  }
  tags = var.tags
}
resource "azurerm_image" "control" {
  name = "${var.prefix}-image-${var.image_version}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_disk { os_type = "Linux" blob_uri = var.vhd_uri caching = "ReadWrite" }
  tags = var.tags
}
resource "azurerm_linux_virtual_machine" "vm" {
  name = "${var.prefix}-vm"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size = var.vm_size
  admin_username = var.admin_username
  source_image_id = azurerm_image.control.id
  network_interface_ids = [azurerm_network_interface.nic.id]
  disable_password_authentication = true
  admin_ssh_key { username = var.admin_username public_key = file(var.ssh_public_key) }
  os_disk { caching = "ReadWrite" storage_account_type = "Standard_LRS" disk_size_gb = 64 }
  tags = var.tags
}
