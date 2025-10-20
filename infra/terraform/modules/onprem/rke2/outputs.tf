output "cluster_name" { value = var.cluster_name }
output "kube_host"    { value = "https://example-onprem-k8s" }
output "kube_ca"      { value = base64encode("PLACEHOLDER_CA") }
output "kube_token"   { value = "PLACEHOLDER_TOKEN" sensitive = true }
