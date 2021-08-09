include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/kubernetes_helm_services/"
}

dependencies {
  paths = ["../kubernetes", "../kubernetes_istio"]
}

locals {
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
}

inputs = merge(
  local.config,
  local.config.helm_charts.apache
)