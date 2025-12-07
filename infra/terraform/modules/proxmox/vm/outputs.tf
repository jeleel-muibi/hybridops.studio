output "vm_id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}

output "node_name" {
  description = "Proxmox node name"
  value       = proxmox_virtual_environment_vm.vm.node_name
}

output "tags" {
  description = "VM tags"
  value       = proxmox_virtual_environment_vm.vm.tags
}
