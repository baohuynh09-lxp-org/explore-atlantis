#----------------------------------------#
#              Query current data        #
#----------------------------------------#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


#----------------------------------------#
#             SaaS Components            #
#----------------------------------------#
### 1. Networking (VPC + EC2 jumphost)
module network {
  source               = "./components/network/"
  global_input         = var.global_input

  # componet-input
  vpc_input            = var.vpc_input
  eks_input            = var.eks_input
}

### 2. IAM Role & Policy (EC2-jumphost/ssm/k8s-vault/...)
module iamRolePolicy {
  source               = "./components/iamRolePolicy/"
  global_input         = var.global_input

  # componet-input
  ec2_input            = var.ec2_input
  eks_input            = var.eks_input

  # internal-reference
  internal_input       = {
    network-vpc_id              = module.network.vpc_id
    network-private_subnets_ids = module.network.private_subnets_ids
  }
}

### 3. Monitoring (cloudwatch)
module monitoring {
  source               = "./components/monitoring/"
  global_input         = var.global_input

  # component-input
  monitoring_input     = var.monitoring_input

  # internal-input
  internal_input       = {
    datasource-aws_caller_account_id         = data.aws_caller_identity.current.account_id
    datasource-aws_current_region            = data.aws_region.current.name
  }
}

### 4. EKS
module eks {
  source               = "./components/eks/"
  global_input         = var.global_input

  # componet-input
  eks_input            = var.eks_input

  # internal-reference
  internal_input       = {
	network-vpc_id          = module.network.vpc_id
	network-public_subnets  = module.network.public_subnets
    network-private_subnets = module.network.private_subnets
  }
}

### 5. Database (postgres/documentDB/opensearch)
module database {
  source               = "./components/database/"
  global_input         = var.global_input

  # componet-input
  rds_input            = var.rds_input
  documentdb_input     = var.documentdb_input

  # internal-reference
  internal_input       = {
	  network-vpc_id                               = module.network.vpc_id
	  network-database_subnet_group_name           = module.network.database_subnet_group_name
    network-security_group_ids_private_access_db = module.network.security_group_ids_private_access_db

    network-private_subnets_ids                  = module.network.private_subnets_ids
    network-database_subnets_ids                 = module.network.database_subnets_ids
    
    monitoring-es_loggroup_arn                   = module.monitoring.es_loggroup_arn
    monitoring-es_access_document_policy         = module.monitoring.es_access_document_policy
  }
}

### 6. redisKafka (redis/Kafka)
module redisKafka {
  source               = "./components/redisKafka/"
  global_input         = var.global_input

  # componet-input
  vpc_input                = var.vpc_input
  redis_input              = var.redis_input
  kafka_input              = var.kafka_input  

  # internal-reference
  internal_input       = {
    network-vpc_id                               = module.network.vpc_id
    monitoring-kafka_loggroup_name               = module.monitoring.kafka_loggroup_name

    network-security_group_ids_private_access_db = module.network.security_group_ids_private_access_db
    network-private_subnets_ids                  = module.network.private_subnets_ids
    network-database_subnets_ids                 = module.network.database_subnets_ids
  }
}
