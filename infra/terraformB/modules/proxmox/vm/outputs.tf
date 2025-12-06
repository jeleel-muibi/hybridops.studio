// file: infra/terraform/modules/proxmox/vm/outputs.tf
// purpose: Expose VM details for inventory and automation
// Maintainer: HybridOps.Studio
// date: 2025-11-29

output "vm_names" {
  description = "List of names of the created VMs"
  value       = [for v in proxmox_virtual_environment_vm.vm : v.name]
}

output "vm_ids" {
  description = "List of IDs of the created VMs in Proxmox"
  value       = [for v in proxmox_virtual_environment_vm.vm : v.vm_id]
}

output "vm_nodes" {
  description = "Names of the Proxmox nodes where the VMs are running"
  value       = [for v in proxmox_virtual_environment_vm.vm : v.node_name]
}

output "vm_ip_addresses" {
  description = "List of static IPs assigned to VMs, if set"
  value       = var.static_ips
}

output "vm_details" {
  description = "Detailed information for each VM, including name, ID, IP, and node assignment"
  value = [
    for idx, v in proxmox_virtual_environment_vm.vm : {
      name       = v.name
      vm_id      = v.vm_id
      ip_address = var.static_ips[idx]
      node       = v.node_name
    }
  ]
}
