resource "null_resource" "vpn_placeholder" {
  triggers = {
    peer_onprem = var.peer_onprem
    peer_cloud  = var.peer_cloud
  }
}
