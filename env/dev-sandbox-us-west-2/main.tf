#---------------------------------------------------#
#             1.module security_group               #
#---------------------------------------------------#
# RDS: SecurityGroup for "private" to access "database"
# NOTE: we dont use default ingress/egress feature from VPC modules since 
#       we need to add "private" subnet's CIDR blocks dynamically
module "security_group" {
  source  = "../../modules/security_group"

  # Providers Within Modules
  # Easier for us to "terraform destroy module separately"
  providers = {
    aws = aws
  }

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
    env   = var.env
    site  = "${var.customer}-${var.env}-${var.region}"
    Name  = "${var.customer}-${var.env}-private-access-db"
  }
}

#---------------------------------------------------#
#                   2.module VPC                    #
#---------------------------------------------------#
module "vpc" {
  source = "../../modules/vpc"

  name = "${var.customer}-${var.env}"

  cidr = "${var.vpc_input.cidr}"

  # Subnet declaration
  azs                 = ["${var.region}a", "${var.region}b", "${var.region}c"]
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
  database_subnet_group_tags = {Name: "${var.customer}-${var.env}-database"}

  tags = {
    env  = var.env
    site = "${var.customer}-${var.env}-${var.region}"
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  ## Using VPC flow logs to debug
  ## Cloudwatch log group and IAM role will be created
  enable_flow_log                      = "${var.vpc_input.enable_flow_log}"
  create_flow_log_cloudwatch_log_group = "${var.vpc_input.enable_flow_log}" ? true : false
  create_flow_log_cloudwatch_iam_role  = "${var.vpc_input.enable_flow_log}" ? true : false
  flow_log_max_aggregation_interval    = 60
  vpc_flow_log_tags = {
    Name = "${var.customer}-${var.env}-flowlog"
  }
}

#---------------------------------------------------#
#                    3.module EKS                   #
#---------------------------------------------------#
# DO-NOT-DELETE provider "kubernetes"
# As it needed for TF to connect & config aws-auth on EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  # Providers Within Modules
  # Easier for us to "terraform destroy module separately"
  providers = {
    aws = aws
  }

  source          = "../../modules/eks"

  cluster_name    = "${var.customer}-${var.env}-eks"
  cluster_version = "${var.eks_input.cluster_version}"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  enable_irsa     = true
  # cluster API server access
  cluster_endpoint_private_access                = "${var.eks_input.cluster_endpoint_private_access}"
  cluster_create_endpoint_private_access_sg_rule = "${var.eks_input.cluster_create_endpoint_private_access_sg_rule}"
  cluster_endpoint_private_access_cidrs          = "${var.eks_input.cluster_endpoint_private_access_cidrs}"

  cluster_endpoint_public_access                 = "${var.eks_input.cluster_endpoint_public_access}"
  cluster_endpoint_public_access_cidrs           = "${var.eks_input.cluster_endpoint_public_access_cidrs}"

  # Additional [roles/users/accounts] add to the aws-auth configmap.
  manage_aws_auth                                = "${var.eks_input.manage_aws_auth}"
  map_roles                                      = "${var.eks_input.map_roles}"
  map_users                                      = "${var.eks_input.map_users}"
  map_accounts                                   = "${var.eks_input.map_accounts}"

  #cluster_encryption_config = [
  #  {
  #    provider_key_arn = "${var.BYOK}",
  #    resources        = ["secrets"]
  #  }
  #]

  cluster_iam_role_name  = "${var.customer}-${var.env}-eks-role"
  node_groups            = merge(local.nodepool_core,local.nodepool_voip)



  tags = {
    env    = var.env
    site   = "${var.customer}-${var.env}-${var.region}"
  }
  depends_on = [
    module.vpc
    #aws_kms_grant.BYOK_access_grant
  ]
}

#---------------------------------------------------#
#                  4.module RDS                     #
#---------------------------------------------------#
### Master PostgreSQL ###
module "rds" {
  source = "../../modules/rds"

  # Providers Within Modules
  # Easier for us to "terraform destroy module separately"
  providers = {
    aws = aws
  }
  
  parameter_group_use_name_prefix = false
  identifier = "${var.customer}-${var.env}-master"

  engine               = "${var.rds_input.engine}"
  engine_version       = "${var.rds_input.engine_version}"
  family               = "${var.rds_input.family}"
  major_engine_version = "${var.rds_input.major_engine_version}"
  instance_class       = "${var.rds_input.instance_class}"

  allocated_storage     = "${var.rds_input.allocated_storage}"
  max_allocated_storage = "${var.rds_input.max_allocated_storage}"
  storage_encrypted     = "${var.rds_input.storage_encrypted}"
  kms_key_id            = "${var.rds_input.storage_encrypted}" ? "${var.BYOK}" : ""

  # Define postgres DB when login
  name     = "${var.rds_credentials.username}"
  # Define postgres' credentials
  username = "${var.rds_credentials.username}"
  password = "${var.rds_credentials.password}"
  port     = "${var.rds_input.port}"

  # A list of DB parameters (map) to apply
  parameters             = "${var.rds_input.db_parameters}"

  multi_az               = "${var.rds_input.multi_az}"
  create_db_subnet_group = "${var.rds_input.create_db_subnet_group}"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = "${data.aws_security_groups.private_access_db.ids}"

  maintenance_window              = "${var.rds_input.maintenance_window}"
  backup_window                   = "${var.rds_input.backup_window}"
  enabled_cloudwatch_logs_exports = "${var.rds_input.enabled_cloudwatch_logs_exports}"

  # Backups are required in order to create a replica
  backup_retention_period = "${var.rds_input.backup_retention_period}"
  skip_final_snapshot     = "${var.rds_input.skip_final_snapshot}"
  deletion_protection     = "${var.rds_input.deletion_protection}"

  tags = {
    env   = var.env
    site  = "${var.customer}-${var.env}-${var.region}"
    Name = "${var.customer}-${var.env}-master-postgres"
  }
  depends_on = [module.vpc]
}

#---------------------------------------------------#
#                5.module DOCUMENTDB                #
#---------------------------------------------------#
module "documentdb" {
  source                          = "../../modules/documentdb"

  # documentDB networking
  cluster_name                    = "${var.customer}-${var.env}-docdb"
  cluster_size                    = "${var.documentdb_input.cluster_size}"
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = "${data.aws_subnet_ids.database.ids}"

  # We intent to import existing security_group (by 'allowed_security_groups') for this module. But this is impossible with error
  # Temparary solution: using "allowed_cidr_blocks" for this module to create new security_group itself.
  #                     will try to improve this in the future.
  allowed_cidr_blocks             = "${var.vpc_input.private_subnets}"
  #allowed_security_groups         = "${data.aws_security_groups.private_access_db.ids}"

  master_username                 = "${var.documentdb_credentials.username}"
  master_password                 = "${var.documentdb_credentials.password}"

  # documentDB infrastructure
  instance_class                  = "${var.documentdb_input.instance_class}"
  db_port                         = "${var.documentdb_input.db_port}"
  auto_minor_version_upgrade      = "${var.documentdb_input.auto_minor_version_upgrade}"
  cluster_family                  = "${var.documentdb_input.cluster_family}"
  engine                          = "${var.documentdb_input.engine}"

  storage_encrypted               = "${var.documentdb_input.storage_encrypted}"
  kms_key_id                      = "${var.documentdb_input.storage_encrypted}" ? "${var.BYOK}" : ""
  skip_final_snapshot             = "${var.documentdb_input.skip_final_snapshot}"

  # documentDB backup
  retention_period                = "${var.documentdb_input.retention_period}"
  preferred_backup_window         = "${var.documentdb_input.preferred_backup_window}"
  preferred_maintenance_window    = "${var.documentdb_input.preferred_maintenance_window}"

  # cluster parameter-group configuration
  cluster_parameters              = "${var.documentdb_input.cluster_parameters}"
}

#---------------------------------------------------#
#              6.module ELASTICACHE-REDIS           #
#---------------------------------------------------#
module elasticache_redis {
  source = "../../modules/elasticache_redis"

  # Elasticache_redis networking
  subnet_ids              = "${data.aws_subnet_ids.database.ids}"
  vpc_id                  = module.vpc.vpc_id
  ingress_cidr_blocks     = "${var.vpc_input.private_subnets}"

  # Elasticache_redis infrastructure
  name_prefix             = "${var.customer}-${var.env}-redis-cluster"
  number_cache_clusters   = "${var.elasticache_redis_input.number_cache_clusters}"
  node_type               = "${var.elasticache_redis_input.node_type}"

  cluster_mode_enabled    = "${var.elasticache_redis_input.cluster_mode_enabled}"
  replicas_per_node_group = "${var.elasticache_redis_input.replicas_per_node_group}"
  num_node_groups         = "${var.elasticache_redis_input.num_node_groups}"

  family                  = "${var.elasticache_redis_input.family}"
  engine_version          = "${var.elasticache_redis_input.engine_version}"
  port                    = "${var.elasticache_redis_input.port}"
  apply_immediately       = true

  multi_az_enabled           = "${var.elasticache_redis_input.multi_az_enabled}"
  automatic_failover_enabled = true

  # Elasticache_redis backup
  maintenance_window         = "${var.elasticache_redis_input.maintenance_window}"
  snapshot_window            = "${var.elasticache_redis_input.snapshot_window}"
  snapshot_retention_limit   = "${var.elasticache_redis_input.snapshot_retention_limit}"

  # Elasticache_redis security access
  at_rest_encryption_enabled = "${var.elasticache_redis_input.at_rest_encryption_enabled}"
  transit_encryption_enabled = "${var.elasticache_redis_input.transit_encryption_enabled}"
  kms_key_id                 = "${var.elasticache_redis_input.at_rest_encryption_enabled}" ? "${var.BYOK}" : ""
  auth_token                 = "${var.elasticache_redis_input.transit_encryption_enabled}" ? "${var.elasticache_redis_credentials.auth_token}" : ""

  # Others
  parameter                  = "${var.elasticache_redis_input.parameter}"

  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-redis-cluster"
  }
}

#---------------------------------------------------#
#                7.module ELASTICSEARCH             #
#---------------------------------------------------#
module "es" {
  source  = "../../modules/es"

  domain_name           = "${var.customer}-${var.env}-es"
  elasticsearch_version = "${var.es_input.elasticsearch_version}"
  access_policies       = data.aws_iam_policy_document.es_access_document.json

  cluster_config_dedicated_master_enabled        = "${var.es_input.cluster_config_dedicated_master_enabled}"
  cluster_config_dedicated_master_type           = "${var.es_input.cluster_config_dedicated_master_type}"
  cluster_config_instance_count                  = "${var.es_input.cluster_config_instance_count}"
  cluster_config_instance_type                   = "${var.es_input.cluster_config_instance_type}"
  cluster_config_zone_awareness_enabled          = "${var.es_input.cluster_config_zone_awareness_enabled}"
  cluster_config_availability_zone_count         = "${var.es_input.cluster_config_availability_zone_count}"
  snapshot_options_automated_snapshot_start_hour = "${var.es_input.snapshot_options_automated_snapshot_start_hour}"

  encrypt_at_rest = {
    enabled    = "${var.es_input.encrypt_at_rest_enabled}"
    kms_key_id = "${var.es_input.encrypt_at_rest_enabled}" ? "${var.BYOK}" : null
  }

  create_service_link_role                       = "${var.es_input.create_service_link_role}"
  domain_endpoint_options_enforce_https          = true

  # These options are available only when BYOK is enabled
  advanced_security_options_enabled                         = "${var.es_input.encrypt_at_rest_enabled}" ? true : false
  advanced_security_options_internal_user_database_enabled  = "${var.es_input.encrypt_at_rest_enabled}" ? true : false
  advanced_security_options_master_user_username            = "${var.es_credentials.username}"
  advanced_security_options_master_user_password            = "${var.es_credentials.password}"

  vpc_options_security_group_ids = [for s in data.aws_security_groups.private_access_db.ids : format("%s", s)]
  vpc_options_subnet_ids         = [for i in data.aws_subnet_ids.database.ids : format("%s", i)]

  ebs_options = {
    ebs_enabled = "true"
    volume_size = "100"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = true
  }

  log_publishing_options_retention = 60
  log_publishing_options = {
    index_slow_logs = {
      enabled                    = true
      cloudwatch_log_group_arn   = "${data.aws_cloudwatch_log_group.es_loggroup.arn}"
    }
    search_slow_logs = {
      enabled                    = true
      cloudwatch_log_group_arn   = "${data.aws_cloudwatch_log_group.es_loggroup.arn}"
    }
    es_application_logs = {
      enabled                    = true
      cloudwatch_log_group_name  = "es_application_logs_dev"
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.es_loggroup,
    aws_cloudwatch_log_resource_policy.es_loggroup_policy
  ]
}

#---------------------------------------------------#
#                8.module MSK (Kafka)               #
#---------------------------------------------------#
module kafka_msk {
  source          = "../../modules/kafka_msk"

  # kafka MSK infrastructure
  cluster_name             = "${var.customer}-${var.env}-kafka-msk"
  number_of_nodes          = length(data.aws_subnet_ids.database.ids)
  client_subnets           = [for i in data.aws_subnet_ids.private.ids : format("%s", i)]
  instance_type            = "${var.kafka_msk_input.instance_type}"
  kafka_version            = "${var.kafka_msk_input.kafka_version}"
  volume_size              = "${var.kafka_msk_input.volume_size}"
  server_properties        = "${var.kafka_msk_input.server_properties}"

  # Kafka MSK monitoring
  prometheus_jmx_exporter  = "${var.kafka_msk_input.prometheus_jmx_exporter}"
  prometheus_node_exporter = "${var.kafka_msk_input.prometheus_node_exporter}"
  cloudwatch_logs_group    = aws_cloudwatch_log_group.kafka_msk_loggroup.name

  # Kafka MSK security
  encryption_at_rest_kms_key_arn      = "${var.BYOK}"
  encryption_in_transit_client_broker = "${var.kafka_msk_input.encryption_in_transit_client_broker}"
  encryption_in_transit_in_cluster    = "${var.kafka_msk_input.encryption_in_transit_in_cluster}"

  enhanced_monitoring                 = "${var.kafka_msk_input.enhanced_monitoring}"
  extra_security_groups               = "${data.aws_security_groups.private_access_db.ids}"

  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-kafka-msk-loggroup"
  }
  depends_on = [module.vpc, aws_cloudwatch_log_group.kafka_msk_loggroup]
}

## EFS CSI
module "efs_csi" {
  source = "../../modules/efs_csi"

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer

  region = var.region
  env = var.env
  customer = var.customer

  depends_on = [
    module.eks
  ]
}


## EFS file system
module "efs" {
  source = "cloudposse/efs/aws"
  version     = "v0.32.7"

  namespace = var.customer
  stage     = var.env
  name      = var.minio_efs_name
  region    = var.region
  vpc_id    = module.vpc.vpc_id
  subnets   = module.vpc.private_subnets

  efs_backup_policy_enabled = true
  allowed_cidr_blocks = var.vpc_input.private_subnets

  depends_on = [
    module.efs_csi
  ]
}