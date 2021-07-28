# main.tf

resource "hcloud_ssh_key" "default" {
  name       = var.config.ssh.name
  public_key = file(var.config.ssh.ssh_key_file)
}