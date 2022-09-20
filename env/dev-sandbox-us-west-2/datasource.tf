#-----------------------------#
#       1.EKS datasource      #
#-----------------------------#
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

#-----------------------------#
#       2.RDS datasource      #
#-----------------------------#
data "aws_security_groups" "private_access_db" {
  # Query security_groups that matches with "tags" information
  tags = {
    Name = "${var.customer}-${var.env}-private-access-db"
  }
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  depends_on = [module.vpc]
}

#-----------------------------#
#    3.DocumentDB datasource  #
#-----------------------------#
data "aws_subnet_ids" "database" {
  # Query subnet that matches with "tags" information
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.customer}-${var.env}-db-*"
  }
  depends_on = [module.vpc]
}

#-------------------------------------------#
#  4.Elasticsearch (Opensearch) datasource  #
#-------------------------------------------#
data aws_cloudwatch_log_group "es_loggroup" {
  name = "${var.customer}-${var.env}-es-loggroup"
  depends_on = [aws_cloudwatch_log_group.es_loggroup]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_policy_document" "es_access_document" {
  statement {
    effect     = "Allow"
    actions    = [ "es:esHttp*" ]
    resources  = [ "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/*/*" ]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}