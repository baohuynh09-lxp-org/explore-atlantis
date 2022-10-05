#---------------------------------------------------#
#          2. module EC2 (devops-workspace)         #
#---------------------------------------------------#
module ec2 {
  source                 = "../../../modules/ec2"

  name                   = "devops-workspace"
  instance_count         = "${var.ec2_input.instance_count}"
  ami                    = "${var.ec2_input.ami}"
  instance_type          = "${var.ec2_input.instance_type}"
  subnet_id              = tolist(var.internal_input.network-private_subnets_ids)[0]
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_ssm_instance_profile.name}"

  tags = {
    env         = "${var.global_input.customer}-${var.global_input.env}"
    site        = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name        = "${var.global_input.customer}-${var.global_input.env}-devops-workspace"
    "lxp:usage" = "jumphost"
  }
  depends_on = [
    aws_iam_role.ec2_ssm_role,
    aws_iam_instance_profile.ec2_ssm_instance_profile,
    aws_iam_role_policy.ec2_ssm_role_policy,
    aws_iam_policy_attachment.ec2_ssm_policy_attachment
  ]
}