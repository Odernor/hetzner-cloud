# variables.tf
# module variables

variable "hcloud_token" {
  type = string
}

variable "config" {
  type = map(any)
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "reponame" {
  type = string
}

variable "chartname" {
  type = string
}

variable "chartversion" {
  type = string
}

variable "values" {
  type = map(any)
}

variable "istio-ingress" {
  type = map(any)
}

variable "virtualservice" {
  type = map(any)
}

variable "gateway" {
  type = map(any)
}
