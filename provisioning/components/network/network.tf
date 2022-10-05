#---------------------------------------------------#
#             1.module security_group               #
#---------------------------------------------------#
# RDS: SecurityGroup for "private" to access "database"
# NOTE: we dont use default ingress/egress feature from VPC modules since 
#       we need to add "private" subnet's CIDR blocks dynamically
module "security_group" {
  source  = "../../../modules/security_group"


  name        = "${var.sg_input.name}"
  description = "private access to database subnets"
  vpc_id      = module.vpc.vpc_id

  count     =  length(module.vpc.private_subnets_cidr_blocks)
  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      description = "documentDB access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      description = "Elasticache access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "ElasticSearch (HTTPS) access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "ElasticSearch (HTTP) access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 9092
      to_port     = 9092
      protocol    = "tcp"
      description = "Kafka_broker (PLAINTEXT) access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 2181
      to_port     = 2181
      protocol    = "tcp"
      description = "Kafka_zookeeper (HTTP) access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
    {
      from_port   = 9094
      to_port     = 9094
      protocol    = "tcp"
      description = "Kafka_broker (TLS) access from private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[count.index]
    },
  ]
  tags = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-private-access-db"
  }
}

#---------------------------------------------------#
#                   2.module VPC                    #
#---------------------------------------------------#
module "vpc" {
  source = "../../../modules/vpc"

  name = "${var.global_input.customer}-${var.global_input.env}"

  cidr = "${var.vpc_input.cidr}"

  # Subnet declaration
  azs                 = ["${var.global_input.region}a", "${var.global_input.region}b", "${var.global_input.region}c"]
  private_subnets     = "${var.vpc_input.private_subnets}"
  public_subnets      = "${var.vpc_input.public_subnets}"
  database_subnets    = "${var.vpc_input.database_subnets}"

  # Create only one NAT in public subnet, internet traffic from other subnets will go through this NAT
  enable_nat_gateway  = true
  single_nat_gateway  = true
  reuse_nat_ips       = true
  external_nat_ip_ids = "${aws_eip.nat_public_ip.*.id}"

  # Enable network ACLs by ourself
  public_dedicated_network_acl      = true
  private_dedicated_network_acl     = true
  database_dedicated_network_acl    = true

  # Associate network ACLs to subnets
  # If dont specify, ACL will have default "inbound/outbound rules": 0.0.0.0/0
  # NOTE: private subnet MUST have "inbound rule" with 0.0.0.0/0 for internet traffic to return back
  #database_inbound_acl_rules          = concat(local.vpc_input.vpc_network_acls["database_inbound"])
  #database_outbound_acl_rules         = concat(local.vpc_network_acls["database_outbound"])

  # Disable database subnet-group for RDS instance to be nested
  create_database_subnet_group   = true
  database_subnet_group_tags = {Name: "${var.global_input.customer}-${var.global_input.env}-database"}

  tags = {
    env  = var.global_input.env
    site = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable VPC Flowlog and publish to centralized logging account
  enable_flow_log                   = var.infra_log_input.enable_flow_log
  flow_log_destination_arn          = "arn:aws:s3:::${var.infra_log_input.s3_bucket_name}"
  flow_log_destination_type         = "s3"
  flow_log_max_aggregation_interval = 600
  flow_log_traffic_type             = "ALL"
  vpc_flow_log_tags = {
    Name = "${var.global_input.customer}-${var.global_input.env}-flowlog"
  }
}

#---------------------------------------------------#
#            3. resource Elastic IP                 #
#---------------------------------------------------#
# Create separated EIP to avoid destroying VPC alongside with EIP
resource "aws_eip" "nat_public_ip" {
  count = 1
  vpc = true
  tags = {
    env   = "${var.global_input.env}"
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-eip-nat"
  }
}

resource "aws_eip" "istio_ingress_public_ip" {
  count = 1
  vpc = true
  tags = {
    env   = "${var.global_input.env}"
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name  = "${var.global_input.customer}-${var.global_input.env}-eip-istio-ingress"
  }
}

# EIP for EKS nodepool_voip workers
resource "aws_eip" "nodepool_voip_worker" {
  count = local.use_nodepool_voip ? var.eks_input.node_groups.nodepool_voip.max_capacity : 0
  vpc = true
  tags = {
    env           = "${var.global_input.env}"
    site          = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name          = "${var.global_input.customer}-${var.global_input.env}-eip-nat"
    nodepool_voip = true
  }
}
