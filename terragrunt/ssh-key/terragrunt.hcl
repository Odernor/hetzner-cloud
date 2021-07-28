include {
    path = find_in_parent_folders()
}

terraform {
    source = "../../modules/ssh-key/"
}

dependencies {
  paths = ["../network"]
}

locals {
    config = yamldecode(file(find_in_parent_folders("config.yaml")))
}

inputs = merge(
    local.config
)