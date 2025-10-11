# Terraform Module — TEMPLATE

> Replace placeholders and move this into a **dedicated repo** when publishing to the Terraform Registry.

## Example usage

```hcl
module "burst_cluster" {
  source      = "github.com/<you>/terraform-azure-hybridops-burst-cluster?ref=v0.1.0"
  prefix      = "hybridops"
  region      = "westeurope"
  burst       = true
  node_count  = 2
  tags = {
    project = "hybridops"
  }
}
```

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `prefix` | `string` | n/a | Name prefix for resources |
| `region` | `string` | n/a | Deployment region |
| `burst` | `bool` | `false` | Whether to enable burst/scale-out |
| `node_count` | `number` | `2` | Initial node count |
| `tags` | `map(string)` | `{}` | Resource tags/labels |

## Outputs
| Name | Description |
|---|---|
| `id` | Primary resource ID (example) |
| `name` | Primary resource name (example) |
| `kubeconfig` | Kubeconfig or access output (example) |
| `dns_name` | DNS name or endpoint (example) |

> Generate a richer Inputs/Outputs section with `terraform-docs` once implemented.

## Versioning & Providers
- Pin Terraform and provider versions in `versions.tf`.
- Configure provider authentication **outside** the module (in the root calling module).

## License
MIT-0
