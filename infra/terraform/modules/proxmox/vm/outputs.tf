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

output "vm_ip_addresses" {
  description = "Assigned IP addresses"
  value       = var.static_ips
}

output "vm_details" {
  description = "Detailed VM information"
  value = [
    for idx, v in proxmox_virtual_environment_vm.vm : {
      name       = v.name
      vm_id      = v.vm_id
      ip_address = var.static_ips[idx]
      node       = v.node_name
    }
  ]
}
