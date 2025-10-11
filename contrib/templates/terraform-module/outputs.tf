# Wire these to real resources in your implementation
output "id" {
  description = "Primary resource ID (example)"
  value       = null
}

output "name" {
  description = "Primary resource name (example)"
  value       = null
}

output "kubeconfig" {
  description = "Kubeconfig or access output (example)"
  value       = null
  sensitive   = true
}

output "dns_name" {
  description = "DNS name or endpoint (example)"
  value       = null
}
