// infra/terraform/modules/proxmox/ipam/main.tf

# Local computations for IPAM module
locals {
  # Convert VLAN numbers to strings to index subnet_map reliably
  alloc_list = [
    for hostname, a in var.allocations :
    {
      hostname = hostname
      vlan_str = tostring(a.vlan)
      offset   = a.offset
    }
  ]

  # Basic validation checks (will be surfaced via null_resource triggers)
  offsets_in_range = alltrue([for a in local.alloc_list : a.offset >= var.offset_min && a.offset <= var.offset_max])
  vlans_exist      = alltrue([for a in local.alloc_list : contains(keys(var.subnet_map), a.vlan_str)])
}

# Null resource to surface validation failures and to produce a tracked object in state.
resource "null_resource" "validate_and_record" {
  triggers = {
    allocations = jsonencode(var.allocations)
    subnet_map  = jsonencode(var.subnet_map)
    checks      = jsonencode({
      offsets_in_range = local.offsets_in_range
      vlans_exist      = local.vlans_exist
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  # Optional: fail early in apply if validation is disabled but checks fail.
  provisioner "local-exec" {
    when    = "create"
    command = "bash -c 'if [ \"${local.offsets_in_range}\" != \"true\" ] || [ \"${local.vlans_exist}\" != \"true\" ]; then echo \"IPAM validation failed\" 1>&2; exit 1; fi'"
    interpreter = ["bash", "-c"]
    # Only run when validate_requests is enabled
    on_failure = var.validate_requests ? "fail" : "continue"
  }
}

# Computation locals (pure calculation)
locals {
  ipv4_addresses = {
    for hostname, alloc in var.allocations :
    hostname => cidrhost(var.subnet_map[tostring(alloc.vlan)], alloc.offset)
  }

  gateways = {
    for vlan_key, cidr in var.subnet_map :
    vlan_key => cidrhost(cidr, 1)
  }

  allocated_by_vlan = {
    for vlan_key in distinct([for _, a in var.allocations : tostring(a.vlan)]) :
    vlan_key => [for name, a in var.allocations : name if tostring(a.vlan) == vlan_key]
  }
}
