#-------------------------------------------#
#         Elasticsearch's cloudwatch        #
#-------------------------------------------#
# Create dedicated Cloudwatch LogGroup for ES cluster
resource "aws_cloudwatch_log_group" "es_loggroup" {
  name              = "${var.global_input.customer}-${var.global_input.env}-es-loggroup"
  retention_in_days = var.monitoring_input.retention_in_days
  tags              = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-es-loggroup"
  }
}

resource "aws_cloudwatch_log_resource_policy" "es_loggroup_policy" {
  policy_name = "${var.global_input.customer}-${var.global_input.env}-es-loggroup-policy"
  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:*"
    }
  ]
}
CONFIG
}

#-------------------------------------------#
#          Kafka-MSK's cloudwatch           #
#-------------------------------------------#
# Create dedicated Cloudwatch LogGroup for kafka-msk
resource "aws_cloudwatch_log_group" "kafka_loggroup" {
  name              = "${var.global_input.customer}-${var.global_input.env}-kafka-msk-loggroup"
  retention_in_days = var.monitoring_input.retention_in_days
  tags              = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-kafka-msk-loggroup"
  }
}
