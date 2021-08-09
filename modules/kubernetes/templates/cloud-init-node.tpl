#cloud-config

%{ if create_disk == "true" }
disk_setup:
  /dev/sdb:
    table_type: 'mbr'
    layout: true
    overwrite: false

fs_setup:
  - label: data
    filesystem: 'ext4'
    device: /dev/sdb
    partition: sdb1
    overwrite: false

mounts:
  - ["/dev/sdb1", "/data"]
%{ endif }

write_files:
  - content: |
      [Service]
      Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
    path: /etc/systemd/system/kubelet.service.d/20-hetzner-cloud.conf
  - content: |
      [Service]
      ExecStart=
      ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd
    path: /etc/systemd/system/docker.service.d/00-cgroup-systemd.conf
  - content: |
      # Allow IP forwarding for kubernetes
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
    path: /etc/sysctl.d/10-kubernetes.conf
  - content: |
      #!/usr/bin/perl
      
      my $sIP = $ARGV[0];
      exit 0 if !$sIP;
      my $iCode=1;
      my $sResult;
      
      my $sCommand = "curl -s --insecure https://${kubernetes_master_ip}:6443/";
      
      while($iCode) {
        $sResult = system($sCommand);
        $iCode = $?;
        sleep(10);
      }
      
      print "$sResult\n";
    path: /run/wait_for_master_ready.pl

apt:
  sources:
    docker.list:
      source: deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable
      keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
    kubernetes.list:
      source: deb https://apt.kubernetes.io/ kubernetes-xenial main
      keyid: 59FE0256827269DC81578F928B57C5C2836F4BEB


packages:
  - docker-ce
  - kubeadm
  - kubectl
  - kubelet

runcmd:
  - systemctl daemon-reload
  - perl /run/wait_for_master_ready.pl ${kubernetes_master_ip}
  - kubeadm join ${kubernetes_master_ip}:6443 --token ${kubernetes_token} --discovery-token-unsafe-skip-ca-verification
  - rm -f /run/wait_for_master_ready.pl