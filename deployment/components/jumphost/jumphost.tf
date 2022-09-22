#------------------------------------------------------------#
#   1. Role/Policy for EC2 to use SSM/write cloudwatch logs  #
#------------------------------------------------------------#
data "aws_subnet_ids" "private" {
  # Query subnet that matches with "tags" information
  vpc_id = var.internal_input.network-vpc_id

  tags = {
    Name = "${var.customer}-${var.env}-private*"
  }
}

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
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-ec2-ssm"
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
      "Resource": "arn:aws:logs:${var.region}:*:log-group:*"
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


#---------------------------------------------------#
#          2. module EC2 (devops-workspace)         #
#---------------------------------------------------#
module ec2 {
  source                 = "../../../modules/ec2"

  name                   = "devops-workspace"
  instance_count         = "${var.ec2_input.instance_count}"
  ami                    = "${var.ec2_input.ami}"
  instance_type          = "${var.ec2_input.instance_type}"
  subnet_id              = tolist(data.aws_subnet_ids.private.ids)[0]
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_ssm_instance_profile.name}"

  tags = {
    env         = "${var.customer}-${var.env}"
    site        = "${var.customer}-${var.env}-${var.region}"
    Name        = "${var.customer}-${var.env}-devops-workspace"
    "lxp:usage" = "jumphost"
  }
  depends_on = [
    aws_iam_role.ec2_ssm_role,
    aws_iam_instance_profile.ec2_ssm_instance_profile,
    aws_iam_role_policy.ec2_ssm_role_policy,
    aws_iam_policy_attachment.ec2_ssm_policy_attachment
  ]
}

#---------------------------------------------------------#
#     3.Role/Policy for IAM user to authen EKS            #
# This role is used for user (using SSH-bastion with SSM) #
# to authen with EKS                                      #
#---------------------------------------------------------#
resource "aws_iam_group" "eks_admin_group" {
  name = "eks-admin"
}

resource "aws_iam_role" "eks_admin_role" {
  name                 = "eks-admin"
  description          = "Allows engineer to connect with EKS cluster"
  max_session_duration = 28800

  # This define who can assume this role
  assume_role_policy   = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          "AWS" : "${var.AWS_ACCOUNT_ID}"
        }
      }
    ]
  })

  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-eks-admin"
  }
}

# The reason for creating customer-managed-policy instead of inline-policy:
# We need this policy to be attached to Group "eks-admin" as well
resource "aws_iam_policy" "eks_admin_policy" {
  name        = "eks-admin-policy"
  path        = "/"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::${var.AWS_ACCOUNT_ID}:role/eks-admin"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:StartSession",
          "ssm:TerminateSession"
        ],
        "Resource": [
          "arn:aws:ec2:${var.region}:${var.AWS_ACCOUNT_ID}:instance/${module.ec2.id.0}",
          "arn:aws:ssm:${var.region}:${var.AWS_ACCOUNT_ID}:session/$${aws:username}-*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "ssm:StartSession",
        "Resource": [
          "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "eks:DescribeCluster",
        "Resource": [
          "arn:aws:eks:${var.region}:${var.AWS_ACCOUNT_ID}:cluster/${var.customer}-${var.env}-eks"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eks_admin_policy_attachment" {
  name       = "eks-admin-policy-attachment"
  roles      = [aws_iam_role.eks_admin_role.name]
  groups     = [aws_iam_group.eks_admin_group.name]
  policy_arn = aws_iam_policy.eks_admin_policy.arn
  depends_on = [
    aws_iam_group.eks_admin_group,
    aws_iam_role.eks_admin_role,
    aws_iam_policy.eks_admin_policy
  ]
}

#---------------------------------------------------#
#    4.Role/Policy for k8s-vault to access KMS      #
#---------------------------------------------------#
resource "aws_iam_user" "vault_k8s_kms" {
  name = "vault-k8s-kms"
  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-vault-k8s-kms"
  }
}

resource "aws_iam_user_policy" "vault_k8s_kms_policy" {
  name = "vault-k8s-kms-policy"
  user = aws_iam_user.vault_k8s_kms.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
      ],
      "Resource": "${var.KMS_vault_autounseal}"
    }
  ]
}
EOF
}
