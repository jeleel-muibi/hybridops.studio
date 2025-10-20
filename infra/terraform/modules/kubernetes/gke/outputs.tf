output "cluster_name"   { value = var.name }
output "kube_host"      { value = "https://example-gke-api" }
output "kube_ca"        { value = base64encode("PLACEHOLDER_CA") }
output "kube_token"     { value = "PLACEHOLDER_TOKEN" sensitive = true }
