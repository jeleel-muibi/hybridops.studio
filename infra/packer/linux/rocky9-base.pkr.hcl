packer {
  required_version = ">= 1.11.0"
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url"         { type = string }
variable "proxmox_username"    { type = string }
variable "proxmox_token"       { type = string }
variable "proxmox_node"        { type = string }
variable "storage_pool"        { type = string   default = "local-lvm" }
variable "network_bridge"      { type = string   default = "vmbr1" }
variable "vm_name"             { type = string   default = "rocky9-base" }
variable "iso_url"             { type = string   default = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-minimal.iso" }
variable "iso_checksum"        { type = string   default = "sha256:CHANGE_ME" }

source "proxmox-iso" "rocky9" {
  proxmox_url      = var.proxmox_url
  username         = var.proxmox_username
  token            = var.proxmox_token
  node             = var.proxmox_node

  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum

  vm_name          = var.vm_name
  cores            = 2
  memory           = 2048
  disk_size        = "20G"
  storage_pool     = var.storage_pool
  network_adapters = [{
    model  = "virtio"
    bridge = var.network_bridge
  }]

  boot_command = [
    "<up><wait><tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.ks<enter>"
  ]
  http_directory = "${path.root}/http"
  ssh_username   = "packer"
  ssh_password   = "packer"
  ssh_timeout    = "30m"
}

build {
  name    = "rocky9-base"
  sources = ["source.proxmox-iso.rocky9"]

  provisioner "shell" {
    inline = [
      "sudo dnf -y update",
      "sudo dnf -y install qemu-guest-agent cloud-init",
      "sudo systemctl enable qemu-guest-agent",
      "sudo systemctl enable cloud-init"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
