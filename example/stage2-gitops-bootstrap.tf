module "gitops-bootstrap" {
  source = "../"
  depends_on = [module.gitops_install]

  cluster_config_file = module.cluster.config_file_path
  gitops_repo_url     = module.gitops.config_repo_url
  git_username        = module.gitops.config_username
  git_token           = module.gitops.config_token
  git_ca_cert         = module.gitops.config_ca_cert
  bootstrap_path      = module.gitops.bootstrap_path
  bootstrap_branch    = module.gitops.bootstrap_branch
  server_name         = module.gitops.server_name
  sealed_secret_cert  = module.cert.cert
  sealed_secret_private_key = module.cert.private_key
  prefix              = var.bootstrap_prefix
  create_webhook      = true
  kubeseal_namespace  = var.kubeseal_namespace
  delete_app_on_destroy = false
  gitops_namespace    = module.gitops_install.argocd_namespace
}

resource null_resource write_variables {
  provisioner "local-exec" {
    command = "echo -n '${module.gitops-bootstrap.secret_name}' > .secret_name"
  }
  provisioner "local-exec" {
    command = "echo -n '${module.gitops-bootstrap.gitops_namespace}' > .gitops_namespace"
  }
  provisioner "local-exec" {
    command = "echo -n '${module.gitops-bootstrap.kubeseal_namespace}' > .kubeseal_namespace"
  }
  provisioner "local-exec" {
    command = "echo -n '${module.gitops-bootstrap.project_name}' > .project_name"
  }
  provisioner "local-exec" {
    command = "echo -n '${module.gitops-bootstrap.app_name}' > .app_name"
  }
}
