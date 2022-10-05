#---------------------------------------------------#
#          LAMBDA & NOTIFICATION                    #
#---------------------------------------------------#
module "notify_slack" {
  source = "../../../modules/notify_slack"

  sns_topic_name    = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
  slack_webhook_url = var.imessage_input.slack_webhook_url
  slack_channel     = var.imessage_input.slack_channel
  slack_username    = "AWS Cloudwatch - ${var.global_input.customer}-${var.global_input.env}"
}
