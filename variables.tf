variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "gitops_namespace" {
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

variable "git_ca_cert" {
  type        = string
  description = "Base64 encoded ca cert of the gitops repository"
  default     = ""
}

variable "bootstrap_path" {
  type        = string
  description = "The path to the bootstrap config for ArgoCD"
}

variable "bootstrap_branch" {
  type        = string
  description = "The branch of the bootstrap repo"
  default     = "main"
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

variable "prefix" {
  type        = string
  description = "Prefix value that should be added to the bootstrapped gitops repo in ArgoCD to prevent collisions"
  default     = ""
}

variable "create_webhook" {
  type        = bool
  description = "Flag indicating that a webhook should be created to notify the argocd instance"
  default     = false
}

variable "delete_app_on_destroy" {
  type        = bool
  description = "Flag indicating that the bootstrap application should be removed from the cluster when the module is destroyed"
  default     = true
}

variable "cascading_delete" {
  type        = bool
  description = "Flag indicating that when the bootstrap application is deleted the child applications should be deleted as well"
  default     = true
}

variable "server_name" {
  type        = string
  description = "The name of the server in the multi-tenant repo"
  default     = "default"
}
