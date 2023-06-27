module "argocd" {
  source = "github.com/cloud-native-toolkit/terraform-tools-argocd"

  cluster_config_file = module.cluster.config_file_path
  cluster_type        = module.cluster.platform.type_code
  ingress_subdomain   = module.cluster.platform.ingress
  tls_secret_name     = module.cluster.platform.tls_secret
  olm_namespace       = module.olm.olm_namespace
  operator_namespace  = module.olm.target_namespace
  name                = "argocd"
}
