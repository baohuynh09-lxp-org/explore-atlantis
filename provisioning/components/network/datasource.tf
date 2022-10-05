#-----------------------------#
#       1.For RDS             #
#-----------------------------#
data "aws_security_groups" "private_access_db" {
  # Query security_groups that matches with "tags" information
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-private-access-db"
  }
}

#-----------------------------#
#       2.For EKS/databases   #
#-----------------------------#
data "aws_subnets" "private" {
  # Query subnet that matches with "tags" information
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-private-*"
  }
}

#-----------------------------#
#      3.For databases        #
#-----------------------------#
data "aws_subnets" "database" {
  # Query subnet that matches with "tags" information
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-db-*"
  }
}