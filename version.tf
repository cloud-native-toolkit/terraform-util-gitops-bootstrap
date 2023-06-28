terraform {
  required_version = ">= 0.15.0"

  required_providers {
    clis = {
      source  = "cloud-native-toolkit/clis"
    }
    gitops = {
      source = "cloud-native-toolkit/gitops"
      version = ">= 0.15.0"
    }
  }
}
