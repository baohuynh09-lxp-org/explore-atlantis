#----------------------------------------#
#              Query current data        #
#----------------------------------------#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


#----------------------------------------#
#             SaaS Components            #
#----------------------------------------#
### 1. Networking (VPC + SecurityGroup)
module network {
  source               = "./components/network/"
  global_input         = var.global_input

  # componet-input
  vpc_input            = var.vpc_input
  sg_input             = var.sg_input
  eks_input            = var.eks_input
  infra_log_input      = var.infra_log_input
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
  rds_input               = var.rds_input
  documentdb_input        = var.documentdb_input
  es_input                = var.es_input
  rds_credentials         = {"username":"postgres","password": data.vault_generic_secret.saas_secret.data["postgres_password"]}
  documentdb_credentials  = {"username":"docdb_user","password": data.vault_generic_secret.saas_secret.data["nosql_password"]}
  es_credentials          = {"username":"elasticuser","password": data.vault_generic_secret.saas_secret.data["es_password"]}

  # internal-reference
  internal_input       = {
    network-vpc_id                               = module.network.vpc_id
    network-database_subnet_group_name           = module.network.database_subnet_group_name
    network-security_group_ids_private_access_db = module.network.security_group_ids_private_access_db

    network-private_subnets_ids                  = module.network.private_subnets_ids
    network-database_subnets_ids                 = module.network.database_subnets_ids

    monitoring-es_loggroup_arn                   = module.monitoring.es_loggroup_arn
    monitoring-es_access_document_policy         = module.monitoring.es_access_document_policy

    # workaround for cluster that has special name (after fix/migration)
    # ex: mcq-uat-documentdb-encrypted
    documentdb_cluster_name_customized           = var.documentdb_cluster_name_customized
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
  redis_credentials        = {"auth_token": data.vault_generic_secret.saas_secret.data["redis_password"]}

  # internal-reference
  internal_input       = {
    network-vpc_id                               = module.network.vpc_id
    monitoring-kafka_loggroup_name               = module.monitoring.kafka_loggroup_name

    network-security_group_ids_private_access_db = module.network.security_group_ids_private_access_db
    network-private_subnets_ids                  = module.network.private_subnets_ids
    network-database_subnets_ids                 = module.network.database_subnets_ids

    # workaround for cluster that has special name (after fix/migration)
    # ex: mcq-uat-kafka-no-tls
    kafka_cluster_name_customized                = var.kafka_cluster_name_customized
  }
}

### 7. EFS-CSI
module efscsi {
  source               = "./components/efscsi/"
  global_input         = var.global_input

  # componet-input
  efscsi_input        = var.efscsi_input

  # internal-reference
  internal_input      = {
    network-vpc_id                = module.network.vpc_id
    network-private_subnets       = module.network.private_subnets
    eks-cluster_oidc_provider_arn = module.eks.cluster_oidc_provider_arn
    eks-cluster_oidc_provider_url = module.eks.cluster_oidc_provider_url
  }
}

### 8. iMessage (dedicated VPC + MacOS + alert)
module imessage {
  source               = "./components/imessage/"
  global_input         = var.global_input

  # componet-input
  imessage_input       = var.imessage_input
}


#----------------------------------------#
#      Migration from flat structure     #
#----------------------------------------#
## FOR EKS
#moved {
#  from = module.eks.module.node_groups.data.cloudinit_config.workers_userdata["nodepool_core"] 
#  to   = module.eks.module.eks.module.node_groups.data.cloudinit_config.workers_userdata["nodepool_core"]
#}
#
#moved {
#  from = module.eks.module.node_groups.aws_eks_node_group.workers["nodepool_core"]
#  to   = module.eks.module.eks.module.node_groups.aws_eks_node_group.workers["nodepool_core"]
#}
#
#
#moved {
#  from = module.eks.module.node_groups.aws_launch_template.workers["nodepool_core"]
#  to   = module.eks.module.eks.module.node_groups.aws_launch_template.workers["nodepool_core"]
#}
#
#moved {
#  from = module.eks.module.node_groups.random_pet.node_groups["nodepool_core"]
#  to   = module.eks.module.eks.module.node_groups.random_pet.node_groups["nodepool_core"]
#}
#
### For Elasticsearch
#moved {
#   from = module.es.aws_cloudwatch_log_group.es_cloudwatch_log_group["es_application_logs"]
#   to   = module.database.module.es.aws_cloudwatch_log_group.es_cloudwatch_log_group["es_application_logs"]
#}

