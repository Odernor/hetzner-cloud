# variables.tf
# module variables

variable "hcloud_token" {
    type = string
}

variable "config" {
    type = map(any)
}
