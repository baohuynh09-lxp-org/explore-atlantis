#---------------------------------------------------#
#                  1.module RDS                     #
#---------------------------------------------------#
module rds {
  source = "../../../modules/rds"

  parameter_group_use_name_prefix = false
  identifier = "${var.global_input.customer}-${var.global_input.env}-master"

  engine                = var.rds_input.engine
  engine_version        = var.rds_input.engine_version
  family                = var.rds_input.family
  major_engine_version  = var.rds_input.major_engine_version
  instance_class        = var.rds_input.instance_class

  allocated_storage     = var.rds_input.allocated_storage
  max_allocated_storage = var.rds_input.max_allocated_storage
  storage_encrypted     = var.rds_input.storage_encrypted
  kms_key_id            = var.rds_input.storage_encrypted ? var.global_input.BYOK : ""

  # Define postgres DB when login
  name     = var.rds_credentials.username
  # Define postgres' credentials
  username = var.rds_credentials.username
  password = var.rds_credentials.password
  port     = var.rds_input.port

  # A list of DB parameters (map) to apply
  parameters             = var.rds_input.db_parameters

  multi_az               = var.rds_input.multi_az
  create_db_subnet_group = var.rds_input.create_db_subnet_group
  db_subnet_group_name   = var.internal_input.network-database_subnet_group_name
  vpc_security_group_ids = var.internal_input.network-security_group_ids_private_access_db

  maintenance_window              = var.rds_input.maintenance_window
  backup_window                   = var.rds_input.backup_window
  enabled_cloudwatch_logs_exports = var.rds_input.enabled_cloudwatch_logs_exports

  # Backups are required in order to create a replica
  backup_retention_period = var.rds_input.backup_retention_period
  skip_final_snapshot     = var.rds_input.skip_final_snapshot
  deletion_protection     = var.rds_input.deletion_protection

  tags = {
    env   = var.global_input.env
    site  = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name = "${var.global_input.customer}-${var.global_input.env}-master-postgres"
  }
}

#---------------------------------------------------#
#                2.module DOCUMENTDB                #
#---------------------------------------------------#
module documentdb {
  source = "../../../modules/documentdb"

  # documentDB networking
  cluster_name                    = var.internal_input.documentdb_cluster_name_customized != "" ? var.internal_input.documentdb_cluster_name_customized : "${var.global_input.customer}-${var.global_input.env}-docdb"
  cluster_size                    = var.documentdb_input.cluster_size
  vpc_id                          = var.internal_input.network-vpc_id
  subnet_ids                      = var.internal_input.network-database_subnets_ids

  # We intent to import existing security_group (by 'allowed_security_groups') for this module. But this is impossible with error
  # Temparary solution: using "allowed_cidr_blocks" for this module to create new security_group itself.
  #                     will try to improve this in the future.
  allowed_cidr_blocks             = var.vpc_input.private_subnets
  #allowed_security_groups         = "${data.aws_security_groups.private_access_db.ids}"

  master_username                 = var.documentdb_credentials.username
  master_password                 = var.documentdb_credentials.password
  # documentDB infrastructure
  instance_class                  = var.documentdb_input.instance_class
  db_port                         = var.documentdb_input.db_port
  auto_minor_version_upgrade      = var.documentdb_input.auto_minor_version_upgrade
  cluster_family                  = var.documentdb_input.cluster_family
  engine                          = var.documentdb_input.engine

  storage_encrypted               = var.documentdb_input.storage_encrypted
  kms_key_id                      = var.documentdb_input.storage_encrypted ? var.global_input.BYOK : ""
  skip_final_snapshot             = var.documentdb_input.skip_final_snapshot

  # documentDB backup
  retention_period                = var.documentdb_input.retention_period
  preferred_backup_window         = var.documentdb_input.preferred_backup_window
  preferred_maintenance_window    = var.documentdb_input.preferred_maintenance_window

  # cluster parameter-group configuron
  cluster_parameters              = var.documentdb_input.cluster_parameters
  deletion_protection             = true
}

#---------------------------------------------------#
#                3.module ELASTICSEARCH             #
#---------------------------------------------------#
module es {
  source = "../../../modules/es"

  domain_name           = "${var.global_input.customer}-${var.global_input.env}-es"
  elasticsearch_version = var.es_input.elasticsearch_version
  access_policies       = var.internal_input.monitoring-es_access_document_policy

  cluster_config_dedicated_master_enabled        = var.es_input.cluster_config_dedicated_master_enabled
  cluster_config_dedicated_master_type           = var.es_input.cluster_config_dedicated_master_type
  cluster_config_instance_count                  = var.es_input.cluster_config_instance_count
  cluster_config_instance_type                   = var.es_input.cluster_config_instance_type
  cluster_config_zone_awareness_enabled          = var.es_input.cluster_config_zone_awareness_enabled
  cluster_config_availability_zone_count         = var.es_input.cluster_config_availability_zone_count
  snapshot_options_automated_snapshot_start_hour = var.es_input.snapshot_options_automated_snapshot_start_hour

  encrypt_at_rest = {
    enabled    = var.es_input.encrypt_at_rest_enabled
    kms_key_id = var.es_input.encrypt_at_rest_enabled ? var.global_input.BYOK : null
  }

  create_service_link_role                       = var.es_input.create_service_link_role
  domain_endpoint_options_enforce_https          = true

  # These options are available only when BYOK is enabled
  advanced_security_options_enabled                         = var.es_input.encrypt_at_rest_enabled ? true : false
  advanced_security_options_internal_user_database_enabled  = var.es_input.encrypt_at_rest_enabled ? true : false
  advanced_security_options_master_user_username            = var.es_credentials.username
  advanced_security_options_master_user_password            = var.es_credentials.password

  vpc_options_security_group_ids = [for s in var.internal_input.network-security_group_ids_private_access_db  : format("%s", s)]
  vpc_options_subnet_ids         = [for i in var.internal_input.network-database_subnets_ids : format("%s", i)]

  ebs_options = {
    ebs_enabled = true
    volume_size = 100
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = true
  }

  log_publishing_options_retention = 60
  log_publishing_options = {
    index_slow_logs = {
      enabled                    = true
      cloudwatch_log_group_arn   = "${var.internal_input.monitoring-es_loggroup_arn}:*"
	}
    search_slow_logs = {
      enabled                    = true
      cloudwatch_log_group_arn   = "${var.internal_input.monitoring-es_loggroup_arn}:*"
    }
    es_application_logs = {
      enabled                    = true
      cloudwatch_log_group_name  = "es_application_logs_dev"
    }
  }
}
