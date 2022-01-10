variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "argocd_namespace" {
  type        = string
  description = "The namespace where argocd has been deployed"
  default     = "openshift-gitops"
}

variable "kubeseal_namespace" {
  type        = string
  description = "The namespace where kubeseal has been deployed"
  default     = "sealed-secrets"
}

variable "gitops_repo_url" {
  type        = string
  description = "The GitOps repo url"
}

variable "git_username" {
  type        = string
  description = "The username used to access the GitOps repo"
}

variable "git_token" {
  type        = string
  description = "The token used to access the GitOps repo"
  sensitive   = true
}

variable "bootstrap_path" {
  type        = string
  description = "The path to the bootstrap config for ArgoCD"
}

variable "sealed_secret_cert" {
  type        = string
  description = "The certificate that will be used to encrypt sealed secrets. If not provided, a new one will be generated"
  default     = ""
}

variable "sealed_secret_private_key" {
  type        = string
  description = "The private key that will be used to decrypt sealed secrets. If not provided, a new one will be generated"
  default     = ""
  sensitive   = true
}
