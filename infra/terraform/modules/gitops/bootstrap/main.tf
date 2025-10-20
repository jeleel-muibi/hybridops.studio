resource "local_file" "bootstrap_manifest" {
  filename = var.output_path
  content  = <<EOT
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hybridops-bootstrap
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${var.repo_url}
    targetRevision: main
    path: ${var.apps_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
EOT
}
