terraform {
  backend "s3" {}

  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.15"
    }
  }
}

# providers
provider "aws" {
  region = var.global_input.region
}

provider "helm" {
  kubernetes {
    #host                   = data.aws_eks_cluster.cluster.endpoint
    #cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    #token                  = data.aws_eks_cluster_auth.cluster.token

    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    token                  = module.eks.cluster_auth_token
  }
}
