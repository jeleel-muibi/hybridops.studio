# Example root usage of the module (for the template repo)
# This file lives under examples/complete/main.tf in the module repo.

terraform {
  required_version = ">= 1.5.0"
}

module "example" {
  source      = "../.."

  prefix      = "hybridops"
  region      = "westeurope"
  burst       = true
  node_count  = 2
  tags = {
    project = "hybridops"
  }
}
