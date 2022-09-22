module network {
  source               = "./components/network/"
  vpc_input            = var.vpc_input
  eks_input            = var.eks_input

  customer             = var.customer
  env                  = var.env
  region               = var.region
  BYOK                 = var.BYOK
  AWS_ACCOUNT_ID       = var.AWS_ACCOUNT_ID
  KMS_vault_autounseal = var.KMS_vault_autounseal
  minio_efs_name       = var.minio_efs_name
}

module jumphost {
  source               = "./components/jumphost/"
  ec2_input            = var.ec2_input
  internal_input       = {
	  network-vpc_id   = module.network.vpc_id
  }

  customer             = var.customer
  env                  = var.env
  region               = var.region
  BYOK                 = var.BYOK
  AWS_ACCOUNT_ID       = var.AWS_ACCOUNT_ID
  KMS_vault_autounseal = var.KMS_vault_autounseal
  minio_efs_name       = var.minio_efs_name
}
