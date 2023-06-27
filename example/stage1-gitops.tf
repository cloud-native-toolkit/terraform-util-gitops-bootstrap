module "gitops" {
  source = "github.com/cloud-native-toolkit/terraform-tools-gitops"

  repo = var.git_repo
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

  provisioner "local-exec" {
    command = "echo -n '${module.gitops.bootstrap_path}' > bootstrap_path"
  }

  provisioner "local-exec" {
    command = "echo -n '${module.gitops.server_name}' > server_name"
  }

  provisioner "local-exec" {
    command = "echo 'Gitops host: ${module.gitops.config_host}'"
  }

  provisioner "local-exec" {
    command = "echo 'Gitops org: ${module.gitops.config_org}'"
  }

  provisioner "local-exec" {
    command = "echo 'Gitops repo: ${module.gitops.config_name}'"
  }

  provisioner "local-exec" {
    command = "echo 'Gitops username: ${module.gitops.config_username}' > git_username"
  }
}
