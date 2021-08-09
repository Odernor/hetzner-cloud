output "node_ips" {
  value = hcloud_server.kubernetes.*.ipv4_address
}

output "kubernetes_ip" {
  value = hcloud_server.kubernetes.0.ipv4_address
}