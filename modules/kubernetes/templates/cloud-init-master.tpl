#cloud-config

write_files:
  - content: |
      network:
        version: 2
        ethernets:
          eth0:
            addresses: [${floating_ip}/32]
    path: /etc/netplan/60-floating-ip.yaml
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
      #!/bin/bash

      export KUBECONFIG=/etc/kubernetes/admin.conf

      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: hcloud
        namespace: kube-system
      stringData:
        token: "${hcloud_token}"
        network: "${network_id}"
      ---
      apiVersion: v1
      kind: Secret
      metadata:
        name: hcloud-csi
        namespace: kube-system
      stringData:
        token: "${hcloud_token}"
      EOF

      kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
      kubectl apply -f https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/ccm-networks.yaml

      kubectl -n kube-system patch daemonset kube-flannel-ds --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'
      kubectl -n kube-system patch deployment coredns --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'
    path: /run/kubernetes_init.sh
      

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
  - sysctl -f --system
  - kubeadm init --token ${kubernetes_token} --token-ttl 1h --pod-network-cidr=10.244.0.0/16 --kubernetes-version=${kubernetes_version} --ignore-preflight-errors=NumCPU --apiserver-cert-extra-sans=${kubernetes_master_ip}
  - sh /run/kubernetes_init.sh
