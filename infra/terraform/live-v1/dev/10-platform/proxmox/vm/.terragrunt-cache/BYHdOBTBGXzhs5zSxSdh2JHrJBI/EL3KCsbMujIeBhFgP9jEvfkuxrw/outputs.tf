// file: infra/terraform/modules/proxmox/vm/outputs.tf
// purpose: Expose VM details for inventory and evidence
// author: Jeleel Muibi
// date: 2025-11-29

output "vm_names" {
  description = "Names of created VMs"
  value       = [for v in proxmox_virtual_environment_vm.vm : v.name]
}

output "vm_ids" {
  description = "Proxmox VMIDs of created VMs"
  value       = [for v in proxmox_virtual_environment_vm.vm : v.vm_id]
}
