
output "control_node_ip" { value = try(azurerm_public_ip.pip[0].ip_address, null) }
output "vm_id" { value = azurerm_linux_virtual_machine.vm.id }
output "version" { value = var.image_version }
