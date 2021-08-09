# main.tf

provider "kubernetes" {
  config_path = var.config.kubernetes_hosts.kubernetes_config
}

provider "helm" {
  kubernetes {
    config_path = var.config.kubernetes_hosts.kubernetes_config
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_base" {
  name  = "istio-base"
  chart = "${path.module}/istio-1.10.3/manifests/charts/base"

  timeout         = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  name  = "istiod"
  chart = "${path.module}/istio-1.10.3/manifests/charts/istio-control/istio-discovery"

  timeout         = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name  = "istio-ingress"
  chart = "${path.module}/istio-1.10.3/manifests/charts/gateways/istio-ingress"

  timeout         = 120
  cleanup_on_fail = true
  force_update    = false
  namespace       = "istio-system"

  dynamic "set" {
    for_each = tomap(var.kubernetes_services.istio.istio_ingressgateway.helm_values)
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [helm_release.istiod]
}

resource "helm_release" "istio_egress" {
  name  = "istio-egress"
  chart = "${path.module}/istio-1.10.3/manifests/charts/gateways/istio-egress"

  timeout         = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [helm_release.istiod]
}
