#---------------------------------------------------#
#              6.module ELASTICACHE-REDIS           #
#---------------------------------------------------#
module redis {
  source = "../../../modules/elasticache_redis"

  # Elasticache_redis networking
  subnet_ids              = var.internal_input.network-database_subnets_ids
  vpc_id                  = var.internal_input.network-vpc_id
  ingress_cidr_blocks     = var.vpc_input.private_subnets

  # Elasticache_redis infrastructure
  name_prefix             = "${var.global_input.customer}-${var.global_input.env}-redis-cluster"
  number_cache_clusters   = var.redis_input.number_cache_clusters
  node_type               = var.redis_input.node_type

  cluster_mode_enabled    = var.redis_input.cluster_mode_enabled
  replicas_per_node_group = var.redis_input.replicas_per_node_group
  num_node_groups         = var.redis_input.num_node_groups

  family                  = var.redis_input.family
  engine_version          = var.redis_input.engine_version
  port                    = var.redis_input.port
  apply_immediately       = true

  multi_az_enabled           = var.redis_input.multi_az_enabled
  automatic_failover_enabled = true

  # Elasticache_redis backup
  maintenance_window         = var.redis_input.maintenance_window
  snapshot_window            = var.redis_input.snapshot_window
  snapshot_retention_limit   = var.redis_input.snapshot_retention_limit

  # Elasticache_redis security access
  at_rest_encryption_enabled = var.redis_input.at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_input.transit_encryption_enabled
  kms_key_id                 = var.redis_input.at_rest_encryption_enabled ? var.global_input.BYOK : ""
  auth_token                 = var.redis_input.transit_encryption_enabled ? var.redis_credentials.auth_token : ""

  # Others
  parameter                  = var.redis_input.parameter

  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-redis-cluster"
  }
}


#---------------------------------------------------#
#                8.module MSK (Kafka)               #
#---------------------------------------------------#
module kafka {
  source          = "../../../modules/kafka_msk"

  # kafka MSK infrastructure
  cluster_name             = "${var.global_input.customer}-${var.global_input.env}-kafka-msk"
  number_of_nodes          = length(var.internal_input.network-database_subnets_ids)
  client_subnets           = [for i in var.internal_input.network-private_subnets_ids : format("%s", i)]
  instance_type            = var.kafka_input.instance_type
  kafka_version            = var.kafka_input.kafka_version
  volume_size              = var.kafka_input.volume_size
  server_properties        = var.kafka_input.server_properties

  # Kafka MSK monitoring
  prometheus_jmx_exporter  = var.kafka_input.prometheus_jmx_exporter
  prometheus_node_exporter = var.kafka_input.prometheus_node_exporter
  cloudwatch_logs_group    = var.internal_input.monitoring-kafka_loggroup_name

  # Kafka MSK security
  encryption_at_rest_kms_key_arn      = var.global_input.BYOK
  encryption_in_transit_client_broker = var.kafka_input.encryption_in_transit_client_broker
  encryption_in_transit_in_cluster    = var.kafka_input.encryption_in_transit_in_cluster

  enhanced_monitoring                 = var.kafka_input.enhanced_monitoring
  extra_security_groups               = var.internal_input.network-security_group_ids_private_access_db

  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-kafka-msk-loggroup"
  }
}

