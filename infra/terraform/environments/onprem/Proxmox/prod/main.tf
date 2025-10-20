module "rke2" {
  source      = "../../modules/onprem/rke2"
  cluster_name= "hybridops-rke2-prod"
  node_count  = 3
}

module "gitops" {
  source      = "../../modules/gitops/bootstrap"
  repo_url    = "https://github.com/you/hybridops-studio.git"
  apps_path   = "deployment/gitops/apps"
  output_path = "output/onprem_prod_gitops_bootstrap.yaml"
}

output "onprem_prod_kube_host" { value = module.rke2.kube_host }
output "gitops_manifest"        { value = module.gitops.bootstrap_manifest_path }
