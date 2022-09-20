terraform {
  backend "s3" {
    region         = "us-west-2"
    bucket         = "lxp-enterprise-saas-uswest2-tf"
    key            = "lxp-enterprise-saas-uswest2-tf.tfstate"

    encrypt        = "true"

    # Using locking state with dynamoDB
    dynamodb_table = "terraform-state-lock"
  }

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
  region = var.region
}

provider "helm" {
  kubernetes {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  }
}