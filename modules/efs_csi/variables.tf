variable "csi_sa_name" {
  type = string
  default = "efs-csi-controller-sa"
}

variable "csi_namespace" {
  type = string
  default = "kube-system"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "customer" {
  type = string
}