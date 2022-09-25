data "aws_security_groups" "macos_public_access" {
  # Query security_groups that matches with "tags" information
  tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-${var.imessage_input.sg_name}"
  }
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
}

data "aws_subnets" "macos_public_subnets" {
  tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-public-*"
  }
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
}