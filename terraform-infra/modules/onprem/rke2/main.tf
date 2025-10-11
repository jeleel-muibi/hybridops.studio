resource "null_resource" "rke2_placeholder" {
  triggers = {
    cluster_name = var.cluster_name
    node_count   = tostring(var.node_count)
  }
}
