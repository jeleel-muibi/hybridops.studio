module "network" {
  source    = "../../modules/network/hubspoke"
  provider  = "gcp"
  hub_cidr  = "10.0.0.0/16"
  spoke_cidrs = ["10.30.0.0/16", "10.40.0.0/16"]
}

module "gke_platform" {
  source      = "../../modules/kubernetes/gke"
  name        = "hybridops-gke"
  region      = var.gcp_region
  node_count  = 3
}

module "gitops" {
  source      = "../../modules/gitops/bootstrap"
  repo_url    = "https://github.com/you/hybridops-studio.git"
  apps_path   = "deployment/gitops/apps"
  output_path = "output/gcp_gitops_bootstrap.yaml"
}

output "gcp_kube_host"   { value = module.gke_platform.kube_host }
output "gitops_manifest" { value = module.gitops.bootstrap_manifest_path }
