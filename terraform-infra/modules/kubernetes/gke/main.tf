resource "null_resource" "gke_placeholder" {
  triggers = {
    name       = var.name
    region     = var.region
    node_count = tostring(var.node_count)
  }
}
