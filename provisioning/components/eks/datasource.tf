#-----------------------------#
#       1.EKS datasource      #
#-----------------------------#
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}


##-------------------------------------------#
##  4.Elasticsearch (Opensearch) datasource  #
##-------------------------------------------#
#data aws_cloudwatch_log_group "es_loggroup" {
#  name = "${var.global_input.customer}-${var.global_input.env}-es-loggroup"
#  depends_on = [aws_cloudwatch_log_group.es_loggroup]
#}
#
#data "aws_caller_identity" "current" {}
#data "aws_region" "current" {}
#data "aws_iam_policy_document" "es_access_document" {
#  statement {
#    effect     = "Allow"
#    actions    = [ "es:esHttp*" ]
#    resources  = [ "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/*/*" ]
#
#    principals {
#      type = "AWS"
#      identifiers = ["*"]
#    }
#  }
#}
