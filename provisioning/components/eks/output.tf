output "cluster_id" {
  description = "The ID of EKS cluster"
  value       = module.eks.cluster_id
}

#--------------------------------#
#       To deploy EFS-CSI        #
#--------------------------------#
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
	value       = data.aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "EKS cluster CA"
  value       = data.aws_eks_cluster.cluster.certificate_authority.0.data
}

output "cluster_auth_token" {
  description = "EKS cluster authentication token"
  value       = data.aws_eks_cluster_auth.cluster.token
}

output "cluster_oidc_provider_arn" {
  description = "EKS cluster OIDC's arn"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_provider_url" {
  description = "EKS cluster OIDC's url"
  value       = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}