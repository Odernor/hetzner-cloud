include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/network/"
}

locals {
  config = yamldecode(file(find_in_parent_folders("config.yaml")))
}

inputs = merge(
  local.config
)