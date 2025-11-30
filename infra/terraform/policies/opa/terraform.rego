
package terraform

# Example: prevent public IPs in prod workspaces
deny[msg] {
  workspace := input.workspace
  contains(workspace, "-prod-")
  some r
  r := input.resources[_]
  r.type == "azurerm_public_ip"
  msg := sprintf("Public IP not allowed in prod: %v", [r.name])
}
