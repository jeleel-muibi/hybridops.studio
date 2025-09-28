
packer {
  required_plugins { azure = { version = ">= 1.4.0" source = "github.com/hashicorp/azure" } }
}
variable "subscription_id" {}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "location" { default = "UK South" }
variable "vm_size" { default = "Standard_D4s_v5" }
variable "capture_container_name" { default = "vhds" }
variable "capture_name_prefix" { default = "control-node" }
source "azure-arm" "control_node" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_id = var.client_id
  client_secret = var.client_secret
  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "0001-com-ubuntu-server-jammy"
  image_sku = "22_04-lts"
  location = var.location
  vm_size = var.vm_size
  capture_container_name = var.capture_container_name
  capture_name_prefix = var.capture_name_prefix
}
build {
  name = "control-node-azure-vhd"
  sources = ["source.azure-arm.control_node"]
  provisioner "file" { source = "../scripts/install_tools.sh" destination = "/tmp/install_tools.sh" }
  provisioner "shell" { inline = ["chmod +x /tmp/install_tools.sh","sudo /tmp/install_tools.sh"] }
}
