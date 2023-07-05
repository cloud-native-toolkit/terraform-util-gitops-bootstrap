module "gitops_install" {
  source = "github.com/cloud-native-toolkit/terraform-k8s-gitops-install"

  cluster_config_file = module.cluster.config_file_path
  cluster_type        = module.cluster.platform.type_code
  ingress_subdomain   = module.cluster.platform.ingress
  tls_secret_name     = module.cluster.platform.tls_secret
  olm_namespace       = module.olm.olm_namespace
  operator_namespace  = module.olm.target_namespace
  sealed_secret_cert  = module.cert.cert
  sealed_secret_private_key = module.cert.private_key
}
