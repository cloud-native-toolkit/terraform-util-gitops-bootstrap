terraform {
  required_version = ">= 0.15.0"

  required_providers {
    clis = {
      source  = "cloud-native-toolkit/clis"
      version = ">= 0.4.2"
    }
    gitops = {
      source = "cloud-native-toolkit/gitops"
      version = ">= 0.15.1"
    }
  }
}
