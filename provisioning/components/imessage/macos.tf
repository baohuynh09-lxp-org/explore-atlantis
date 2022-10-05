#---------------------------------------------------#
#         ELASTIC IP                                #
#---------------------------------------------------#
# Create separated EIP to avoid destroying VPC alongside with EIP
resource "aws_eip" "macos_public_ip" {
  count = var.imessage_input.count
  vpc   = true
  tags  = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-eip-mac-${var.imessage_input.name}"
  }
}

#---------------------------------------------------#
#          DEDICATED MACOS                          #
#---------------------------------------------------#
resource "aws_ec2_host" "macos_host" {
  count             = var.imessage_input.count
  instance_type     = var.imessage_input.instance_type
#  availability_zone = var.global_input.region
  availability_zone = "${var.global_input.region}a"
  host_recovery     = "off"
  auto_placement    = "on"
  tags = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-mac-instance-${var.imessage_input.name}"
  }
}

#---------------------------------------------------#
#         EC2                                       #
#---------------------------------------------------#
resource "aws_instance" "macos_instance"{
  count                       = var.imessage_input.count
  ami                         = var.imessage_input.ami
  instance_type               = var.imessage_input.instance_type
  subnet_id                   = tolist(data.aws_subnets.macos_public_subnets.ids)[0]
  vpc_security_group_ids      = data.aws_security_groups.macos_public_access.ids
  host_id                     = aws_ec2_host.macos_host[count.index].id
  key_name                    = aws_key_pair.macos_generated_key.key_name
  associate_public_ip_address = true
  user_data                   = filebase64("components/imessage/user_data.sh")

  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-macos-instance-${var.imessage_input.name}"
  }
  depends_on = [
    module.vpc,
    module.security_group,
    aws_key_pair.macos_generated_key,
    aws_ec2_host.macos_host
  ]
}

resource "aws_eip_association" "macos_eip_assoc" {
  count         = var.imessage_input.count
  instance_id   = aws_instance.macos_instance[count.index].id
  allocation_id = aws_eip.macos_public_ip[count.index].id
  depends_on = [
    aws_instance.macos_instance,
    aws_eip.macos_public_ip
  ]
}

#---------------------------------------------------#
#          ALERT & RECOVERY                         #
#---------------------------------------------------#
resource "aws_cloudwatch_metric_alarm" "macos_not_healthy" {
  count                     = var.imessage_input.count
  alarm_name                = "MacOS ${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}-${aws_instance.macos_instance[count.index].id} not healthy"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "3"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Minimum"
  threshold                 = "0"
  treat_missing_data        = "breaching"
  alarm_description         = "This metric monitors ec2's health check"
  actions_enabled           = "true"
  alarm_actions             = [
    "arn:aws:automate:${var.global_input.region}:ec2:reboot",
    module.notify_slack.slack_topic_arn
  ]
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.macos_instance[count.index].id
  }
  tags = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-mac-healthcheck-alarm-${var.imessage_input.name}"
  }
  depends_on = [
    module.notify_slack,
    aws_instance.macos_instance
  ]
}
