
output "control_node_ip" { value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip }
output "instance_id" { value = google_compute_instance.vm.id }
output "version" { value = var.image }
