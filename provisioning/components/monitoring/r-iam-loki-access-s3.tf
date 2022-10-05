#---------------------------------------------------#
#              IAM User: Loki (logging/tracing)     #
#---------------------------------------------------#
resource "aws_iam_user" "loki" {
  name = "loki-logging-tracing"
  path = "/"

  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-loki-logging-tracing"
  }
}

#---------------------------------------------------#
#          IAM Policy: Loki logging/tracing         #
#---------------------------------------------------#
resource "aws_iam_user_policy" "loki_access_s3_logging_tracing_policy" {
  name = "loki-access-s3-logging-tracing-policy"
  user = aws_iam_user.loki.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "TempoPermissions",
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ],
        "Resource": [
          "${module.s3_loki_logging.s3_bucket_arn}",
          "${module.s3_loki_logging.s3_bucket_arn}/*",
          "${module.s3_loki_tracing.s3_bucket_arn}",
          "${module.s3_loki_tracing.s3_bucket_arn}/*",
        ]
      }
    ]
  })
}
