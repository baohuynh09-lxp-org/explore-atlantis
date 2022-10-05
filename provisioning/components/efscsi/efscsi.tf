## EFS CSI
module "efs_csi" {
  source            = "../../../modules/efs_csi"

  oidc_provider_arn = var.internal_input.eks-cluster_oidc_provider_arn
  oidc_provider_url = var.internal_input.eks-cluster_oidc_provider_url

  region            = var.global_input.region
  env               = var.global_input.env
  customer          = var.global_input.customer
}

## EFS file system
module "efs" {
  source      = "../../../modules/efs"

  namespace   = var.global_input.customer
  stage       = var.global_input.env
  region      = var.global_input.region
  name        = var.efscsi_input.name
  vpc_id      = var.internal_input.network-vpc_id
  subnets     = var.internal_input.network-private_subnets

  efs_backup_policy_enabled = var.efscsi_input.efs_backup_policy_enabled
  allowed_cidr_blocks       = var.vpc_input.private_subnets

  depends_on = [
    module.efs_csi
  ]
}

