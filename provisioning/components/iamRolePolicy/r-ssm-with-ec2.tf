#------------------------------------------------------------#
#           2. Role/Policy for EC2 to use SSM                #
#           Log/write actions to cloudwatch logs             #
#------------------------------------------------------------#
# Create role "ec2_ssm_role" to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"
  description = "Allows EC2 instances to call AWS SessionManager on your behalf"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Sid": "",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-ec2-ssm"
  }
}

# Attach role "ec2_ssm_role" with policy to send logs to CloudWatch
resource "aws_iam_role_policy" "ec2_ssm_role_policy" {
  name = "ec2_ssm_role_policy"
  role = "${aws_iam_role.ec2_ssm_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${var.global_input.region}:*:log-group:*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "ec2_ssm_instance_profile"
  role = "${aws_iam_role.ec2_ssm_role.name}"
  depends_on = [aws_iam_role.ec2_ssm_role]
}

resource "aws_iam_policy_attachment" "ec2_ssm_policy_attachment" {
  name       = "ec2_ssm_policy_attachment"
  roles      = [aws_iam_role.ec2_ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  depends_on = [aws_iam_role.ec2_ssm_role]
}
