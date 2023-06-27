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
  numeric = true
}

data clis_check clis {
  clis = ["helm","jq","argocd","kubectl","oc"]
}

data gitops_repo_config repo {
  server_name = var.server_name
  branch = var.bootstrap_branch
  bootstrap_url = var.gitops_repo_url
  username = var.git_username
  token = var.git_token
  ca_cert = var.git_ca_cert
}

resource gitops_metadata metadata {
  server_name = var.server_name
  branch = var.bootstrap_branch
  credentials = data.gitops_repo_config.repo.git_credentials
  config = data.gitops_repo_config.repo.gitops_config
  kube_config_path = var.cluster_config_file
}

resource null_resource create_tls_secret {
  triggers = {
    kubeconfig = var.cluster_config_file
    namespace = var.kubeseal_namespace
    secret_name = local.secret_name
    bin_dir = data.clis_check.clis.bin_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-tls-secret.sh ${self.triggers.namespace} ${self.triggers.secret_name}"

    environment = {
      BIN_DIR     = self.triggers.bin_dir
      KUBECONFIG  = self.triggers.kubeconfig
      PRIVATE_KEY = nonsensitive(var.sealed_secret_private_key)
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
    bin_dir = data.clis_check.clis.bin_dir
  }
}

resource null_resource bootstrap_argocd {
  depends_on = [null_resource.create_tls_secret]

  triggers = {
    argocd_host = data.external.argocd_config.result.host
    argocd_user = data.external.argocd_config.result.user
    argocd_password = data.external.argocd_config.result.password
    namespace = var.gitops_namespace
    git_repo = var.gitops_repo_url
    git_token = var.git_token
    git_ca_cert = var.git_ca_cert
    prefix = local.prefix
    bin_dir = data.clis_check.clis.bin_dir
    kubeconfig = var.cluster_config_file
    delete_app = var.delete_app_on_destroy
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/argocd-bootstrap.sh '${self.triggers.argocd_host}' '${self.triggers.argocd_user}' '${self.triggers.namespace}' '${self.triggers.git_repo}' '${var.git_username}' '${var.bootstrap_path}' '${var.branch}' '${self.triggers.prefix}'"

    environment = {
      ARGOCD_PASSWORD = self.triggers.argocd_password
      GIT_TOKEN = nonsensitive(self.triggers.git_token)
      GIT_CA_CERT = self.triggers.git_ca_cert
      BIN_DIR = self.triggers.bin_dir
      KUBECONFIG = self.triggers.kubeconfig
      CASCADING_DELETE = var.cascading_delete
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/argocd-cleanup.sh '${self.triggers.argocd_host}' '${self.triggers.argocd_user}' '${self.triggers.namespace}' '${self.triggers.git_repo}' '${self.triggers.prefix}'"

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
