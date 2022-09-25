#---------------------------------------------------#
#                     module VPC                    #
#---------------------------------------------------#
module vpc {
  source = "../../../modules/vpc"
  

  name                = "${var.global_input.customer}-${var.global_input.env}"
  cidr                = var.imessage_input.cidr
  # Subnet declaration
  azs                 = ["${var.global_input.region}a", "${var.global_input.region}b", "${var.global_input.region}c"]
  public_subnets      = var.imessage_input.public_subnets

  # Enable network ACLs by ourself
  public_dedicated_network_acl  = true

  tags = {
    env  = var.global_input.env
    site = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  ## Using VPC flow logs to debug
  ## Cloudwatch log group and IAM role will be created
  enable_flow_log                      = var.imessage_input.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.imessage_input.enable_flow_log ? true : false
  create_flow_log_cloudwatch_iam_role  = var.imessage_input.enable_flow_log ? true : false
  flow_log_max_aggregation_interval    = 60
  vpc_flow_log_tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-flowlog"
  }
}

#---------------------------------------------------#
#             module SECURITY GROUP                 #
#---------------------------------------------------#
module "security_group" {
  source      = "../../../modules/security_group"
  name        = "${var.global_input.customer}-${var.global_input.env}-${var.imessage_input.sg_name}"
  description = "Public access to MacOS instance"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access to MacOS instance"
      cidr_blocks = join(",", var.imessage_whitelistSSH)
    },
    {
      from_port   = 5900
      to_port     = 5900
      protocol    = "tcp"
      description = "VNC access to MacOS instance"
      cidr_blocks = var.imessage_whitelistVNC
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access to MacOS instance"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access to MacOS instance"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8001
      to_port     = 8100
      protocol    = "tcp"
      description = "grpc access between MacOS agents"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "outbound rules"
    }
  ]
  tags = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-${var.imessage_input.sg_name}"
  }
}

#---------------------------------------------------#
#                 SSH KEY                           #
#---------------------------------------------------#
resource "tls_private_key" "macos_sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "macos_generated_key" {
  key_name   = var.imessage_input.key_name
  public_key = tls_private_key.macos_sshkey.public_key_openssh
}
