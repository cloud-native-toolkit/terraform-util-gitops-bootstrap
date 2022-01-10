locals {
  tmp_dir = "${path.cwd}/.tmp/gitops-bootstrap"
  secret_name = "custom-sealed-secret-${random_string.suffix.result}"
  argocd_config_file = "${local.tmp_dir}/argocd-config.json"
  argocd_config = jeondecode(data.local_file.argocd_config.content)
}

resource random_string suffix {
  length  = 6
  special = false
  lower   = true
  upper   = false
  number  = true
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["helm","jq","argocd"]
}

resource null_resource create_tls_secret {
  triggers = {
    kubeconfig = var.cluster_config_file
    namespace = var.kubeseal_namespace
    secret_name = local.secret_name
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-tls-secret.sh ${self.triggers.namespace} ${self.triggers.secret_name}"

    environment = {
      KUBECONFIG  = self.triggers.kubeconfig
      PRIVATE_KEY = var.sealed_secret_private_key
      CERT        = var.sealed_secret_cert
      TMP_DIR     = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/delete-tls-secret.sh ${self.triggers.namespace} ${self.triggers.secret_name}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}
resource null_resource retrieve_argocd_config {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-argocd-config.sh '${var.gitops_namespace}' '${local.argocd_config_file}'"

    environment = {
      KUBECONFIG = var.cluster_config_file
      BIN_DIR = module.setup_clis.bin_dir
    }
  }
}

data local_file argocd_config {
  depends_on = [null_resource.retrieve_argocd_config]

  filename = local.argocd_config_file
}

resource null_resource bootstrap_argocd {
  depends_on = [null_resource.create_tls_secret]

  triggers = {
    argocd_host = local.argocd_config.host
    argocd_user = local.argocd_config.user
    argocd_password = local.argocd_config.password
    git_repo = var.gitops_repo_url
    git_token = var.git_token
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/argocd-bootstrap.sh ${self.triggers.argocd_host} ${self.triggers.argocd_user} ${var.gitops_namespace} ${self.triggers.git_repo} ${var.git_username} ${var.bootstrap_path}"

    environment = {
      ARGOCD_PASSWORD = nonsensitive(self.triggers.argocd_password)
      GIT_TOKEN = nonsensitive(self.triggers.git_token)
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/argocd-cleanup.sh ${self.triggers.argocd_host} ${self.triggers.argocd_user} ${self.triggers.git_repo}"

    environment = {
      ARGOCD_PASSWORD = self.triggers.argocd_password
    }
  }
}
