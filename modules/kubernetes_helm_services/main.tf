# main.tf

provider "kubernetes" {
  config_path = var.config.kubernetes_hosts.kubernetes_config
}

provider "helm" {
  kubernetes {
    config_path = var.config.kubernetes_hosts.kubernetes_config
  }
}

provider "kubectl" {
  config_path = var.config.kubernetes_hosts.kubernetes_config
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "helm_release" "helm" {
  name       = var.name
  repository = var.reponame
  chart      = var.chartname
  version    = var.chartversion

  namespace = var.namespace

  dynamic "set" {
    for_each = var.values
    content {
      name  = set.key
      value = set.value
    }
  }
  set {
    name  = "podLabels.app"
    value = var.name
  }
  set {
    name  = "podLabels.version"
    value = var.chartversion
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

resource "kubectl_manifest" "istio_gateway" {
  count     = var.istio-ingress.create ? 1 : 0
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ${var.name}-gateway
  namespace: ${var.namespace}
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: ${var.gateway.port1.number}
      name: ${var.gateway.port1.name}
      protocol: ${var.gateway.port1.protocol}
    hosts:
    - "*"
  - port:
      number: ${var.gateway.port2.number}
      name: ${var.gateway.port2.name}
      protocol: ${var.gateway.port2.protocol}
    hosts:
    - "*"
YAML
  depends_on = [
    helm_release.helm
  ]
}

resource "kubectl_manifest" "istio_virtual_service" {
  count     = var.istio-ingress.create ? 1 : 0
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ${var.name}
  namespace: ${var.namespace}
spec:
  hosts:
  - "${var.virtualservice.hosts}"
  gateways:
  - ${var.name}-gateway
  http:
  - name: ${var.name}
    match:
    - uri:
        prefix: "${var.virtualservice.prefix}"
    rewrite:
      uri: "${var.virtualservice.rewrite}"
    route:
    - destination:
        host: ${var.name}
YAML
  depends_on = [
    helm_release.helm
  ]
}

resource "kubectl_manifest" "istio_authorization" {
  count     = var.istio-ingress.create ? 1 : 0
  yaml_body = <<YAML
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ${var.name}-viewer
  namespace: ${var.namespace}
spec:
  selector:
    matchLabels:
      app: ${var.name}
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
YAML
  depends_on = [
    helm_release.helm
  ]
}
