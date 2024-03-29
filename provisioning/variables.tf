#---------------------------------------#
#               GLOBAL                  #
#---------------------------------------#
variable "global_input" {
  type = object({
    customer             = string
    env                  = string
    region               = string
    BYOK                 = string
    AWS_ACCOUNT_ID       = string
  })
  description = "All global variables"
}

#----------------------------------------#
#          Internal variables            #
#----------------------------------------#
variable "internal_input" {
  type        = any
  default     = {}
  description = "internal input"
}

#----------------------------------------#
#          module VAULT                  #
#----------------------------------------#
variable "vault_terraformapprole_token" {
  type        = string
  default     = ""
  description = "token to access Vault & get DB passwords"
}

variable "vault_input" {
  type = object({
    vault_endpoint              = string
    vault_aws_backend_role_name = string
    role_arns                   = list(string)
    default_sts_ttl             = number
    infra_secret_path           = string
  })
  default     = {
    vault_endpoint              = "http://127.0.0.1:8200"
    vault_aws_backend_role_name = "terraform-deployer" 
    role_arns                   = [""]
    default_sts_ttl             = 900 # seconds
    infra_secret_path           = "secret/infra/dev_sandbox"
  }
  description = "input for Vault setting"
}

#----------------------------------------#
#              module VPC                #
#----------------------------------------#
variable "vpc_input" {
  type = object({
    cidr                = string
    private_subnets     = list(string)
    public_subnets      = list(string)
    database_subnets    = list(string)
    list_port_db_access = list(string)
    enable_flow_log     = bool
  })
  default = {
    cidr                = "10.10.0.0/16"
    public_subnets      = ["10.10.1.0/24"]
    private_subnets     = ["10.10.11.0/24","10.10.12.0/24","10.10.13.0/24"]
    database_subnets    = ["10.10.21.0/24","10.10.22.0/24"]
    list_port_db_access = [5432,27017,6379,80,443,9092,2181]
    enable_flow_log     = false
  }
  description = "All settings for VPC"
}

#----------------------------------------#
#         Infra logs                     #
#----------------------------------------#
variable "infra_log_input" {
  type = object({
    s3_bucket_name        = string
    enable_flow_log       = bool
    enable_cloudtrail_log = bool
  })
  default = {
    s3_bucket_name        = "no-name"
    enable_flow_log       = false
    enable_cloudtrail_log = false
  }
}

#----------------------------------------#
#          module monitoring             #
#----------------------------------------#
variable "monitoring_input" {
  type = object({
    retention_in_days      = number
    logging_bucket         = string
    logging_lifecycle_rule = any
    tracing_bucket         = string
    tracing_lifecycle_rule = any
  })
  default = {
    retention_in_days      = 30
    logging_bucket         = "loki-logging"
    logging_lifecycle_rule = []
    tracing_bucket         = "tempo-tracing"
    tracing_lifecycle_rule = []
  }
  description = "All settings for monitoring module"
}

#----------------------------------------#
#              module EKS                #
#----------------------------------------#
variable "eks_input" {
  type        = any
  default     = {}
  description = "All settings for EKS"
}

#----------------------------------------#
#         module SECURITY-GROUP          #
#----------------------------------------#
variable "sg_input" {
  type = object({
    name = string
  })

  default = {
    name = "private-access-db"
  }
  description = "All settings for security-group"
}

#----------------------------------------#
#    module RDS (Replica PostgreSQL)     #
#----------------------------------------#
variable "rds_credentials" {
  type = object({
    username = string
    password = string
  })

  # Default values for RDS' credentials
  default = {
    username = ""
    password = ""
  }
  sensitive = true
  description = "All settings for RDS credentials "
}

variable "rds_input" {
 type = object({
   engine                          = string
   engine_version                  = string
   family                          = string
   major_engine_version            = string
   instance_class                  = string
   allocated_storage               = string
   max_allocated_storage           = string
   storage_encrypted               = string
   port                            = string
   db_parameters                   = list(map(string))
   multi_az                        = string 
   create_db_subnet_group          = string 
   maintenance_window              = string
   backup_window                   = string
   enabled_cloudwatch_logs_exports = list(string)

   # Backups are required in order to create a replica
   backup_retention_period         = number
   skip_final_snapshot             = string
   deletion_protection             = string
 })

 # Default values for RDS 
 default = {
   engine                          = "postgres"
   engine_version                  = "10.10"
   family                          = "postgres10"
   major_engine_version            = "10.10"
   instance_class                  = "db.t3.large"
   allocated_storage               = 20
   max_allocated_storage           = 100
   storage_encrypted               = false
   port                            = 5432
   db_parameters                   = []
   multi_az                        = true 
   create_db_subnet_group          = false 
   maintenance_window              = "Mon:00:00-Mon:03:00"
   backup_window                   = "03:00-06:00"
   enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

   # Backups are required in order to create a replica
   backup_retention_period         = 1
   skip_final_snapshot             = true
   deletion_protection             = false
 }
 description = "All settings for RDS input parameters"
}

#----------------------------------------#
#           module DocumentDB            #
#----------------------------------------#
variable "documentdb_cluster_name_customized" {
  type        = string
  default     = ""
  description = "workaround for cluster that has special name (after fix/migration)"
}

variable "documentdb_credentials" {
  type = object({
    username = string
    password = string
  })

  # Default values for documentDB's credentials
  default = {
    username = ""
    password = ""
  }
  description = "All settings for documentDB credentials"
}

variable "documentdb_input" {
  type = object({
    cluster_size                    = string
    instance_class                  = string
    db_port                         = number
    auto_minor_version_upgrade      = bool
    
    retention_period                = number
    preferred_backup_window         = string
    preferred_maintenance_window    = string
    
    cluster_family                  = string
    engine                          = string
    storage_encrypted               = bool
    skip_final_snapshot             = bool
    cluster_parameters              = list(map(string))
  })

  # Default values for documentDB parameter
  default = {
    cluster_size                    = 1
    instance_class                  = "db.t3.medium"
    db_port                         = 27017
    auto_minor_version_upgrade      = "false"
    
    retention_period                = 5
    preferred_backup_window         = "07:00-09:00"
    preferred_maintenance_window    = "Mon:22:00-Mon:23:00"
    
    cluster_family                  = ""
    engine                          = ""
    storage_encrypted               = false
    skip_final_snapshot             = true
    cluster_parameters              = []
  }
  description = "All settings for documentDB parameter"
}

#----------------------------------------#
#       module ELASTICACHE_REDIS         #
#----------------------------------------#
variable "redis_credentials" {
  type = object({
    auth_token = string
  })

  # Default values for Elasticache_redis's credentials
  default = {
    auth_token = ""
  }
  description = "All settings for Elasticache_redis credentials"
}

variable "redis_input" {
  type = object({
    number_cache_clusters      = number
    node_type                  = string
    cluster_mode_enabled       = bool
    replicas_per_node_group    = number
    num_node_groups            = number
    family                     = string
    engine_version             = string
    port                       = number
    multi_az_enabled           = bool
    maintenance_window         = string
    snapshot_window            = string
    snapshot_retention_limit   = number
    at_rest_encryption_enabled = bool
    transit_encryption_enabled = bool
    parameter                  = list(map(string))
  })

  default = {
    number_cache_clusters      = 2
    node_type                  = "cache.t3.small"
    cluster_mode_enabled       = true
    replicas_per_node_group    = 1
    num_node_groups            = 1
    family                     = "redis6.x"
    engine_version             = "6.x"
    port                       = 6379
    multi_az_enabled           = true
    apply_immediately          = true
    maintenance_window         = "mon:03:00-mon:04:00"
    snapshot_window            = "04:00-06:00"
    snapshot_retention_limit   = 7
    at_rest_encryption_enabled = true
    transit_encryption_enabled = true
    parameter = []
  }
  description = "All settings for Elasticache_redis parameter"
}

#----------------------------------------#
#         module ELASTICSEARCH           #
#----------------------------------------#
variable "es_credentials" {
  type = object({
    username = string
    password = string
  })

  # Default values for elasticsearch credentials
  default = {
    username = "elasticuser"
    password = ""
  }
  description = "All settings for elasticsearch credentials"
}

variable "es_input" {
  type = object({
    elasticsearch_version                                     = string
    cluster_config_dedicated_master_enabled                   = bool
    cluster_config_dedicated_master_type                      = string
    cluster_config_instance_count                             = number
    cluster_config_instance_type                              = string
    cluster_config_zone_awareness_enabled                     = bool
    cluster_config_availability_zone_count                    = number
    snapshot_options_automated_snapshot_start_hour            = string
    encrypt_at_rest_enabled                                   = bool
    create_service_link_role                                  = bool
    ebs_options_ebs_enabled                                   = bool
    ebs_options_volume_size                                   = number
  })

  default = {
    elasticsearch_version                                     = 7.10
    cluster_config_dedicated_master_enabled                   = false
    cluster_config_dedicated_master_type                      = "t3.medium.elasticsearch"
    cluster_config_instance_count                             = 3
    cluster_config_instance_type                              = "t3.medium.elasticsearch"
    cluster_config_zone_awareness_enabled                     = true
    cluster_config_availability_zone_count                    = 3
    snapshot_options_automated_snapshot_start_hour            = "23"
    encrypt_at_rest_enabled                                   = true
    create_service_link_role                                  = true
    ebs_options_ebs_enabled                                   = true
    ebs_options_volume_size                                   = 50
  }
  description = "All settings for elasticsearch cluster"
}

#----------------------------------------#
#         module KAFKA (MSK)             #
#----------------------------------------#
variable "kafka_cluster_name_customized" {
  type        = string
  default     = ""
  description = "workaround for cluster that has special name (after fix/migration)"
}

variable "kafka_input" {
  type = object({
    instance_type                       = string
    kafka_version                       = string
    volume_size                         = number
    prometheus_jmx_exporter             = bool
    prometheus_node_exporter            = bool
    server_properties                   = map(string)
    encryption_in_transit_client_broker = string
    encryption_in_transit_in_cluster    = bool
    enhanced_monitoring                 = string
  })

  default = {
    instance_type                       = "kafka.t3.medium"
    kafka_version                       = "2.6.2"
    volume_size                         = 100
    prometheus_jmx_exporter             = false
    prometheus_node_exporter            = true
    server_properties                   = {
        "auto.create.topics.enable"  = "true"
        "default.replication.factor" = "2"
    }
    encryption_in_transit_client_broker = "PLAINTEXT"
    encryption_in_transit_in_cluster    = false

    enhanced_monitoring                 = "PER_BROKER"
  }
  description = "All settings for Kafka MSK cluster"
}

#----------------------------------------#
#     module EC2 (devops-workspace)      #
#----------------------------------------#
variable "ec2_input" {
  type = object({
    instance_count         = number
    ami                    = string
    instance_type          = string
  })

  # Default values for Elasticache_redis's credentials
  default = {
    instance_count         = 1
    ami                    = "ami-03d5c68bab01f3496"
    instance_type          = "t2.medium"
  }
  description = "All settings for EC2 "
}


#----------------------------------------#
#          module EFS-CSI                #
#----------------------------------------#
variable "efscsi_input" {
  type = object({
    name                      = string
    efs_backup_policy_enabled = bool
  })
  default = {
    name                      = "minio"
    efs_backup_policy_enabled = true
  }
  description = "All settings for EFS"
}

#----------------------------------------#
#          module MACOS (iMessage)       #
#----------------------------------------#
variable "imessage_input" {
  type = object({
    # macos configuration
    sg_name         = string
    ami             = string
    instance_type   = string
    count           = number
    name            = string
    key_name        = string

    # dedicated vpc
    sg_name         = string
    region          = string
    cidr            = string
    public_subnets  = list(string)
    enable_flow_log = bool

    # slack alert
    slack_webhook_url = string
    slack_channel     = string

  })
  default = {
    sg_name         = "public-access-mac"
    ami             = "ami-07a0f396e6eb97c9f"
    instance_type   = "mac1.metal"
    count           = 1
    name            = "devsandbox_mac"
    key_name        = "macos_sshkey"

    sg_name         = "public-access-mac"
    region          = "us-east-1"
    cidr            = "10.11.0.0/16"
    public_subnets  = ["10.11.1.0/24"]
    enable_flow_log = false

    slack_webhook_url = "none"
    slack_channel     = "none"
  }
  description = "All settings for imessage (network + macos + alert)"
}

variable "imessage_whitelistSSH" {
  type        = list(string)
  description = "whitelist CIDRs for SSH"
  default     = [
    "20.189.120.18/32",
    "162.252.208.0/24",
    "162.252.209.0/24",
    "192.206.63.0/24",
    "162.221.90.0/24",
    "38.39.177.0/24",
    "38.39.178.0/24",
    "38.39.188.0/24",
    "38.39.189.0/24",
    "38.39.186.0/24",
    "38.39.187.0/24",
    "38.39.184.0/24",
    "38.39.185.0/24",
    "38.39.183.0/24",
    "38.23.35.0/24",
    "38.23.36.0/24",
    "38.23.37.0/24",
    "198.206.135.0/24"
  ]
}

variable "imessage_whitelistVNC"{
  type        = string
  description = "whitelist CIDR for VNC"
  default     = "20.189.120.18/32"
}
