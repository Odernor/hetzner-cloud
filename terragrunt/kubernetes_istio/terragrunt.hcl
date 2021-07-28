include {
    path = find_in_parent_folders()
}

terraform {
    source = "../../modules/kubernetes_istio/"
}

dependencies {
  paths = ["../kubernetes"]
}

locals {
    config = yamldecode(file(find_in_parent_folders("config.yaml")))
}

inputs = merge(
    local.config,
    local.config.kubernetes.istio
)