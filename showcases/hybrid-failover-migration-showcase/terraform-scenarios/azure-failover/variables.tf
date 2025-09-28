
variable "prefix" { type = string default = "ctrl-failover" }
variable "location" { type = string default = "uksouth" }
variable "image_version" { type = string default = "latest" }
variable "vhd_uri" { type = string }
variable "vm_size" { type = string default = "Standard_D4s_v5" }
variable "admin_username" { type = string default = "azureuser" }
variable "ssh_public_key" { type = string }
variable "create_public_ip" { type = bool default = true }
variable "vnet_cidr" { type = string default = "10.60.0.0/16" }
variable "subnet_cidr" { type = string default = "10.60.1.0/24" }
variable "tags" { type = map(string) default = {
  project = "hybridops.studio"
  component = "control-node"
  stage = "failover"
} }
