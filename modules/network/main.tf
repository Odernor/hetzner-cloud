# main.tf

resource "hcloud_network" "network" {
    name = var.config.network.name
    ip_range = var.config.network.network_ip_range
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = var.config.network.type
  network_zone = var.config.network.network_zone
  ip_range     = var.config.network.subnet_ip_range
}

resource "hcloud_floating_ip" "kubernetes" {
  type = "ipv4"
  home_location = var.config.kubernetes.location
  description = "Kubernetes Loadbalancer IP"
  name = "${var.config.network.name}-loadbalancer"
  labels = {
    "ingressip" = "true"
  }
}
