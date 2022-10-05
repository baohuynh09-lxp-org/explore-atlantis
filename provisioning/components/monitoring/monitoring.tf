#---------------------------------------------------#
#                1.module S3 (Loki logging)         #
#---------------------------------------------------#
module s3_loki_logging {
  source                   = "../../../modules/s3"

  bucket                   = var.monitoring_input.logging_bucket
  acl                      = "private"
  # Allow deletion of non-empty bucket
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true

  # S3 Bucket Ownership Controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  lifecycle_rule           = var.monitoring_input.logging_lifecycle_rule
  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-s3-loki-logging"
  }
}

#---------------------------------------------------#
#                2.module S3 (Loki tracing)         #
#---------------------------------------------------#
module s3_loki_tracing {
  source                   = "../../../modules/s3"

  bucket                   = var.monitoring_input.tracing_bucket
  acl                      = "private"
  # Allow deletion of non-empty bucket
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true

  # S3 Bucket Ownership Controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  lifecycle_rule           = var.monitoring_input.tracing_lifecycle_rule

  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-s3-loki-tracing"
  }
}
