# Terragrunt/Terraform source for creating kubernetes cluster

## Used programs

* terraform
* terragrunt

## Installation

* Install tfwitch:

```bash
curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | sudo bash
```

* Install tgswitch:

```bash
curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | sudo bash

```

* Change to terragrunt Folder
* Switch terraform/terragrunt versions

```bash
tfswitch -b ~/bin # Automatically chooses version from terragrunt.hcl
tgswitch -b ~/bin # Choose Version >= 0.31.0
```

* Add ~/bin to PATH

```bash
export PATH=$PATH:/home/<user>/bin
```

* Export Variable TF_VAR_hcloud_token with the API Token generated in Hetzner Cloud Console

* Run terragrunt to apply kubernetes cluster to hetzner

```bash
terragrunt run-all apply
```
