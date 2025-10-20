module "network" {
  source    = "../../modules/network/hubspoke"
  provider  = "azure"
  hub_cidr  = "10.0.0.0/16"
  spoke_cidrs = ["10.10.0.0/16", "10.20.0.0/16"]
}

module "aks_platform" {
  source      = "../../modules/kubernetes/aks"
  name        = "hybridops-aks"
  location    = var.location
  node_count  = 3
}

module "gitops" {
  source      = "../../modules/gitops/bootstrap"
  repo_url    = "https://github.com/you/hybridops-studio.git"
  apps_path   = "deployment/gitops/apps"
  output_path = "output/azure_gitops_bootstrap.yaml"
}

output "azure_kube_host"  { value = module.aks_platform.kube_host }
output "gitops_manifest"  { value = module.gitops.bootstrap_manifest_path }
