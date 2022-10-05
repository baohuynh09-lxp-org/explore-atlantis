#---------------------------------------------------#
#                    1.module EKS                   #
#---------------------------------------------------#
# DO-NOT-DELETE provider "kubernetes"
# As it needed for TF to connect & config aws-auth on EKS
#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#  token                  = data.aws_eks_cluster_auth.cluster.token
#}

module "eks" {
  source          = "../../../modules/eks"

  cluster_name    = "${var.global_input.customer}-${var.global_input.env}-eks"
  cluster_version = "${var.eks_input.cluster_version}"
  vpc_id          = var.internal_input.network-vpc_id
  subnets         = var.internal_input.network-private_subnets
  enable_irsa     = true
  # cluster API server access
  cluster_endpoint_private_access                = "${var.eks_input.cluster_endpoint_private_access}"
  cluster_create_endpoint_private_access_sg_rule = "${var.eks_input.cluster_create_endpoint_private_access_sg_rule}"
  cluster_endpoint_private_access_cidrs          = "${var.eks_input.cluster_endpoint_private_access_cidrs}"

  cluster_endpoint_public_access                 = "${var.eks_input.cluster_endpoint_public_access}"
  cluster_endpoint_public_access_cidrs           = "${var.eks_input.cluster_endpoint_public_access_cidrs}"

  # Additional [roles/users/accounts] add to the aws-auth configmap.
  manage_aws_auth                                = "${var.eks_input.manage_aws_auth}"
  map_roles                                      = "${var.eks_input.map_roles}"
  map_users                                      = "${var.eks_input.map_users}"
  map_accounts                                   = "${var.eks_input.map_accounts}"

  #cluster_encryption_config = [
  #  {
  #    provider_key_arn = "${var.global_input.BYOK}",
  #    resources        = ["secrets"]
  #  }
  #]

  cluster_iam_role_name        = "${var.global_input.customer}-${var.global_input.env}-eks-role"
  node_groups                  = merge(local.nodepool_core,local.nodepool_voip)
  workers_additional_policies  = var.eks_input.workers_additional_policies

  tags = {
    env    = var.global_input.env
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
  }
}
