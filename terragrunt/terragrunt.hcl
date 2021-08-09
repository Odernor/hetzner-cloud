# terragrunt.hcl
# main terragrunt hcl

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "hcloud" {
  token = var.hcloud_token
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.27"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.11.2"
    }
  }
}
EOF
}

terragrunt_version_constraint = ">=0.31.0"
terraform_version_constraint  = ">=1.0.2"