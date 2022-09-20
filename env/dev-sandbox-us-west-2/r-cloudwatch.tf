#-------------------------------------------#
#         Elasticsearch's cloudwatch        #
#-------------------------------------------#
# Create dedicated Cloudwatch LogGroup for ES cluster
resource "aws_cloudwatch_log_group" "es_loggroup" {
  name = "${var.customer}-${var.env}-es-loggroup"
  retention_in_days = 0
  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-es-loggroup"
  }
}

resource "aws_cloudwatch_log_resource_policy" "es_loggroup_policy" {
  policy_name = "${var.customer}-${var.env}-es-loggroup-policy"
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
resource "aws_cloudwatch_log_group" "kafka_msk_loggroup" {
  name = "${var.customer}-${var.env}-kafka-msk-loggroup"
  retention_in_days = 0
  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-kafka-msk-loggroup"
  }
}