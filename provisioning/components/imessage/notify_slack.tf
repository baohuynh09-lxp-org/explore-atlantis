#---------------------------------------------------#
#          LAMBDA & NOTIFICATION                    #
#---------------------------------------------------#
module "notify_slack" {
#  source = "../../modules/notify_slack"
  source = "terraform-aws-modules/notify-slack/aws"
  version = "5.3.0"

  sns_topic_name = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"

  slack_webhook_url = "https://hooks.slack.com/services/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"
  slack_channel     = "leapxpert_alert"
  slack_username    = "AWS Cloudwatch - ${var.global_input.customer}-${var.global_input.env}"
}
