resource "null_resource" "aks_placeholder" {
  triggers = {
    name       = var.name
    location   = var.location
    node_count = tostring(var.node_count)
  }
}
