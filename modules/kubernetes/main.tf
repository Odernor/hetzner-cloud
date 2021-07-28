# main.tf

locals {
  random_waitscript = "${path.module}/${uuid()}.pl"
}

data "hcloud_network" "network" {
    name = var.config.network.name
}

data "hcloud_floating_ip" "kubernetes" {
  name = "${var.config.network.name}-loadbalancer"
}

data "template_file" "cloud_init_master" {
  template = file("templates/cloud-init-master.tpl")

  vars = {
    floating_ip = data.hcloud_floating_ip.kubernetes.ip_address
    kubernetes_version = var.config.kubernetes.kubernetes_version
    kubernetes_master_ip = "${trimsuffix(var.config.network.subnet_ip_range, "0/24")}10"
    kubernetes_token = var.config.kubernetes.kubernetes_token
    hcloud_token = var.hcloud_token
    network_id = data.hcloud_network.network.id
  }
}

data "template_file" "cloud_init_node" {
  template = file("templates/cloud-init-node.tpl")

  vars = {
    floating_ip = data.hcloud_floating_ip.kubernetes.ip_address
    kubernetes_master_ip = "${trimsuffix(var.config.network.subnet_ip_range, "0/24")}10"
    kubernetes_token = var.config.kubernetes.kubernetes_token
  }
}

resource "hcloud_server" "kubernetes" {
  count = var.config.kubernetes.number_of_nodes
  name        = "${var.config.kubernetes.name}-${count.index+1}"
  server_type = var.config.kubernetes.server_type
  image       = var.config.kubernetes.image
  location    = var.config.kubernetes.location

  ssh_keys = [ var.config.ssh.name ]

  user_data = count.index == 0 ? data.template_file.cloud_init_master.rendered : data.template_file.cloud_init_node.rendered
}

resource "hcloud_server_network" "kubernetes" {
  count = var.config.kubernetes.number_of_nodes
  server_id = element(hcloud_server.kubernetes.*.id, count.index)
  network_id = data.hcloud_network.network.id
  ip = "${trimsuffix(var.config.network.subnet_ip_range, "0/24")}${count.index+10}"
}

data "template_file" "waitscript" {
  template = <<EOT
#!/usr/bin/perl
      
      my $iCode=1;
      my $sResult;
      
      my $sCommand = "curl -s --insecure https://$${kubernetes_master_ip}:6443/";
      
      while($iCode) {
        print "WAITING for Kubernetes Master is READY!\n";
        $sResult = system($sCommand);
        $iCode = $?;
        sleep(10) if $iCode;
      }
      
      print "$sResult\n";
EOT

  vars = {
    kubernetes_master_ip = hcloud_server.kubernetes.0.ipv4_address
  }
}

resource "local_file" "waitscript" {
  filename = local.random_waitscript
  content  = data.template_file.waitscript.rendered

  lifecycle {
    ignore_changes = [
      filename,
      content
    ]
  }
}

resource "null_resource" "waitscript" {
  provisioner "local-exec" {
    command = "perl ${local.random_waitscript}"
  }
  depends_on = [local_file.waitscript]

  triggers = {
    kubernetes_id = hcloud_server.kubernetes.0.id
  }
}

resource "null_resource" "copykubeconf" {
  provisioner "local-exec" {
    command = "scp -o \"StrictHostKeyChecking=no\" root@${hcloud_server.kubernetes.0.ipv4_address}:/etc/kubernetes/admin.conf ${var.config.kubernetes.kubernetes_config}"
  }
  depends_on = [null_resource.waitscript]
}