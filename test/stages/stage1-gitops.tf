module "gitops" {
  source = "github.com/cloud-native-toolkit/terraform-tools-gitops"

  repo = var.git_repo
  host = ""
  type = ""
  org  = ""
  token = ""
  username = ""
  gitops_namespace = var.gitops_namespace
  sealed_secrets_cert = module.cert.cert
}

resource null_resource gitops_output {
  provisioner "local-exec" {
    command = "echo -n '${module.gitops.config_repo}' > git_repo"
  }

  provisioner "local-exec" {
    command = "echo -n '${module.gitops.config_token}' > git_token"
  }
}
