#-------------------------------------------#
#        1.Kafka MSK datasource             #
#-------------------------------------------#
data aws_cloudwatch_log_group "kafka_loggroup" {
  name = "${var.global_input.customer}-${var.global_input.env}-kafka-msk-loggroup"
  depends_on = [aws_cloudwatch_log_group.kafka_loggroup]
}

#-------------------------------------------#
#  2.Elasticsearch (Opensearch) datasource  #
#-------------------------------------------#
data aws_cloudwatch_log_group "es_loggroup" {
  name = "${var.global_input.customer}-${var.global_input.env}-es-loggroup"
  depends_on = [aws_cloudwatch_log_group.es_loggroup]
}

data aws_iam_policy_document "es_access_document" {
  statement {
    effect     = "Allow"
    actions    = [ "es:esHttp*" ]
    resources  = [ "arn:aws:es:${var.internal_input.datasource-aws_current_region}:${var.internal_input.datasource-aws_caller_account_id}:domain/*/*" ]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}
