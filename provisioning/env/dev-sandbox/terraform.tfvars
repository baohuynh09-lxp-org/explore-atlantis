#---------------------------------------#
#               GLOBAL                  #
#---------------------------------------#
# full tag-name: "dev-sandbox-us-west-2"
global_input = {
  customer       = "dev"
  env            = "sandbox"
  region         = "us-west-2"
  BYOK           = "arn:aws:kms:us-west-2:498691965545:key/ad99c35e-fff0-4b65-b655-8e095272861d"
  AWS_ACCOUNT_ID = "4986-9196-5545"
}

#----------------------------------------#
#              module VPC                #
#----------------------------------------#
vpc_input = {
  cidr                 = "10.10.0.0/16"
  public_subnets       = ["10.10.1.0/24"]
  private_subnets      = ["10.10.11.0/24","10.10.12.0/24","10.10.13.0/24"]
  database_subnets     = ["10.10.21.0/24","10.10.22.0/24","10.10.23.0/24"]
  enable_flow_log      = false

  # List ports for private to access database subnet
  # 5432->RDS, 27017->documentDB, 6379->Elasticache(Redis), 80-443->Elasticsearch, 9092->MSK-cluster, 2181->MSK-zookeeper
  list_port_db_access  = [5432,27017,6379,80,443,9092,2181,9094]

  # Setting more NACL, see link below
  # https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/examples/network-acls/main.tf
}

#----------------------------------------#
#         module monitoring              #
#----------------------------------------#
monitoring_input = {
  retention_in_days  = 120
}


#----------------------------------------#
#              module EKS                #
#----------------------------------------#
eks_input = {
  cluster_version                                = "1.22"
  cluster_endpoint_private_access                = "true"
  cluster_create_endpoint_private_access_sg_rule = "true"
  cluster_endpoint_private_access_cidrs          = ["10.10.11.0/24","10.10.12.0/24","10.10.13.0/24"]

  cluster_endpoint_public_access                 = "true"
  # This take effect only when "cluster_endpoint_public_access" = true
  cluster_endpoint_public_access_cidrs           = ["20.189.120.18/32", "13.77.155.71/32"]

  manage_aws_auth                                = true
  map_roles                                      = [
      {
        # NOTE: dont use fullpath role-arn, remove prefix (org/team/...)
        # ex: WRONG  // arn:aws:iam::498691965545:role/aws-reserved/sso.amazonaws.com/ap-southeast-1/AWSReservedSSO_AdministratorAccess_89dafe7ae9f45061
        #     CORRECT// arn:aws:iam::498691965545:role/AWSReservedSSO_AdministratorAccess_89dafe7ae9f45061
        #     (remove aws-reserved/sso.amazonaws.com/ap-southeast-1)
        rolearn  = "arn:aws:iam::498691965545:role/AWSReservedSSO_AdministratorAccess_89dafe7ae9f45061"
        username = "devsandbox-admin:{{SessionName}}"
        groups   = ["system:masters"]
      },
    ]
  map_users                                      = []
  map_accounts                                   = []


  node_groups = {
    nodepool_core = {
      name                          = "nodepool_core"
      #subnets                       = module.vpc.private_subnets
      desired_capacity              = 2
      max_capacity                  = 3
      min_capacity                  = 2
      instance_types                = ["t3.xlarge"]
      capacity_type                 = "ON_DEMAND"
      create_launch_template        = true
      #worker_additional_security_group_ids = [aws_security_group.public_subnet_access_private.id]
    }

    #nodepool_voip = {
    #  name                          = "nodepool_voip"
    #  #subnets                       = module.vpc.public_subnets
    #  desired_capacity              = 1 
    #  max_capacity                  = 1 
    #  min_capacity                  = 1 
    #  instance_types                = ["t3.small"]
    #  capacity_type                 = "ON_DEMAND"
    #  public_ip                     = true
    #  create_launch_template        = true
    #  kubelet_extra_args            = "--register-with-taints=nodepool_voip=true:NoSchedule --node-labels=nodepool_voip=true"
    #}
  }
}

#----------------------------------------#
#         module SECURITY-GROUP          #
#----------------------------------------#
sg_input = {
  name = "private-access-db"
}

#----------------------------------------#
#    module RDS (Replica PostgreSQL)     #
#----------------------------------------#
rds_input = {
  engine                = "postgres"
  engine_version        = "10.18"
  family                = "postgres10"
  major_engine_version  = "10.18"
  instance_class        = "db.t3.micro"

  allocated_storage     = 10
  max_allocated_storage = 20
  storage_encrypted     = false
  port                  = 5432
  db_parameters         = [
    {
      name      = "rds.force_ssl"
      value     = 0
    },
    {
      name      = "ssl"
      value     = 0
    }
  ]

  multi_az               = true
  create_db_subnet_group = false

  maintenance_window              = "Sun:00:00-Sun:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Backups are required in order to create a replica
  backup_retention_period = 5
  skip_final_snapshot     = true
  deletion_protection     = false
}

#----------------------------------------#
#           module DocumentDB            #
#----------------------------------------#
documentdb_input = {
  cluster_size                    = 2
  instance_class                  = "db.t4g.medium"
  db_port                         = 27017
  auto_minor_version_upgrade      = false
  
  retention_period                = 5
  preferred_maintenance_window    = "Sun:00:00-Sun:03:00"
  preferred_backup_window         = "03:00-06:00"
  
  cluster_family                  = "docdb4.0"
  engine                          = "docdb"
  storage_encrypted               = false
  skip_final_snapshot             = true
  cluster_parameters              = [
    {
      apply_method = "pending-reboot"
      name         = "tls"
      value        = "disabled"
    },
    {
      apply_method = "immediate"
      name         = "profiler"
      value        = "enabled"
    },
    {
      apply_method = "immediate"
      name         = "profiler_threshold_ms"
      value        = "200"
    }
  ]

}

#----------------------------------------#
#       module ELASTICACHE-REDIS         #
#----------------------------------------#
redis_input = {
  number_cache_clusters      = 2
  node_type                  = "cache.t3.medium"
  cluster_mode_enabled       = false
  replicas_per_node_group    = 1
  num_node_groups            = 1
  family                     = "redis6.x"
  engine_version             = "6.x"
  port                       = 6379
  multi_az_enabled           = true
  apply_immediately          = true
  maintenance_window         = "sun:00:00-sun:03:00"
  snapshot_window            = "03:00-06:00"
  snapshot_retention_limit   = 5
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  parameter = [
    #{
    #  ### Example to use key-value for passing parameters
    #  name  = "repl-backlog-size"
    #  value = "16384"
    #}
  ]
}


#----------------------------------------#
#         module ELASTICSEARCH           #
#----------------------------------------#
es_input = {
  elasticsearch_version                          = "7.10"
  cluster_config_dedicated_master_enabled        = false
  cluster_config_dedicated_master_type           = "t3.small.elasticsearch"
  cluster_config_instance_count                  = 3
  cluster_config_instance_type                   = "t3.small.elasticsearch"
  cluster_config_zone_awareness_enabled          = true
  cluster_config_availability_zone_count         = 3
  snapshot_options_automated_snapshot_start_hour = "23"
  encrypt_at_rest_enabled                        = false
  transit_encryption_enabled                     = true
  create_service_link_role                       = false
  ebs_options_ebs_enabled                        = true
  ebs_options_volume_size                        = 100
}

#----------------------------------------#
#         module KAFKA (MSK)             #
#----------------------------------------#
kafka_input = {
  instance_type                       = "kafka.t3.small"
  kafka_version                       = "2.6.2"
  volume_size                         = 100
  prometheus_jmx_exporter             = false
  prometheus_node_exporter            = true
  server_properties                   = {
      "auto.create.topics.enable"  = "true"
      "default.replication.factor" = "2"
  }
  encryption_in_transit_client_broker = "TLS" # TLS / PLAINTEXT
  encryption_in_transit_in_cluster    = true
  enhanced_monitoring                 = "PER_BROKER"
}

#----------------------------------------#
#      module EC2 (devops-workspace)     #
#----------------------------------------#
ec2_input = {
  instance_count         = 1
  ami                    = "ami-098e42ae54c764c35"
  instance_type          = "t2.medium"
}

#----------------------------------------#
#          module minio-efs              #
#----------------------------------------#
minio_efs_input = {
  name = "minio"
}
