resource "null_resource" "hubspoke_placeholder" {
  triggers = {
    hub_cidr    = var.hub_cidr
    spoke_count = tostring(length(var.spoke_cidrs))
    provider    = var.provider
  }
}
