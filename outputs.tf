output "secret_name" {
  description = "The name of the kubeseal secret that was created"
  value       = local.secret_name
  depends_on  = [null_resource.bootstrap_argocd]
}

output "gitops_namespace" {
  description = "The name of the kubeseal secret that was created"
  value       = var.gitops_namespace
  depends_on  = [null_resource.bootstrap_argocd]
}

output "kubeseal_namespace" {
  description = "The name of the namespace namespace where kubeseal is deployed"
  value       = var.kubeseal_namespace
  depends_on  = [null_resource.bootstrap_argocd]
}

output "project_name" {
  value       = var.prefix == "" ? "${var.prefix}-0-bootstrap" : "0-bootstrap"
  depends_on  = [null_resource.bootstrap_argocd]
}

output "app_name" {
  value       = var.prefix == "" ? "${var.prefix}-0-bootstrap" : "0-bootstrap"
  depends_on  = [null_resource.bootstrap_argocd]
}
