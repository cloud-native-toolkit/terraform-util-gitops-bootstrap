locals {
  tmp_dir = "${path.cwd}/.tmp/gitops-bootstrap"
  secret_name = "custom-sealed-secret-${random_string.suffix.result}"
  prefix = var.prefix != null ? replace(var.prefix, "_", "-") : ""
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

  clis = ["helm","jq","argocd","kubectl","oc"]
}

resource null_resource create_tls_secret {
  triggers = {
    kubeconfig = var.cluster_config_file
    namespace = var.kubeseal_namespace
    secret_name = local.secret_name
    bin_dir = module.setup_clis.bin_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-tls-secret.sh ${self.triggers.namespace} ${self.triggers.secret_name}"

    environment = {
      BIN_DIR     = self.triggers.bin_dir
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
      BIN_DIR    = self.triggers.bin_dir
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

data external argocd_config {
  program = ["bash", "${path.module}/scripts/get-argocd-config.sh"]

  query = {
    namespace = var.gitops_namespace
    kube_config = var.cluster_config_file
    bin_dir = module.setup_clis.bin_dir
  }
}

resource null_resource bootstrap_argocd {
  depends_on = [null_resource.create_tls_secret]

  triggers = {
    argocd_host = data.external.argocd_config.result.host
    argocd_user = data.external.argocd_config.result.user
    argocd_password = data.external.argocd_config.result.password
    git_repo = var.gitops_repo_url
    git_token = var.git_token
    prefix = local.prefix
    bin_dir = module.setup_clis.bin_dir
    kubeconfig = var.cluster_config_file
    delete_app = var.delete_app_on_destroy
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/argocd-bootstrap.sh '${self.triggers.argocd_host}' '${self.triggers.argocd_user}' '${var.gitops_namespace}' '${self.triggers.git_repo}' '${var.git_username}' '${var.bootstrap_path}' '${self.triggers.prefix}'"

    environment = {
      ARGOCD_PASSWORD = self.triggers.argocd_password
      GIT_TOKEN = nonsensitive(self.triggers.git_token)
      BIN_DIR = self.triggers.bin_dir
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/argocd-cleanup.sh '${self.triggers.argocd_host}' '${self.triggers.argocd_user}' '${self.triggers.git_repo}' '${self.triggers.prefix}'"

    environment = {
      ARGOCD_PASSWORD = self.triggers.argocd_password
      BIN_DIR = self.triggers.bin_dir
      KUBECONFIG = self.triggers.kubeconfig
      DELETE_APP = self.triggers.delete_app
    }
  }
}

resource null_resource create_webhook {
  depends_on = [null_resource.bootstrap_argocd]
  count = var.create_webhook ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/argocd-webhook.sh '${data.external.argocd_config.result.host}' '${var.gitops_repo_url}'"

    environment = {
      GIT_TOKEN = nonsensitive(var.git_token)
    }
  }
}
