#----------------------------------------#
#              module VPC                #
#----------------------------------------#
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

#----------------------------------------#
#              module EKS                #
#----------------------------------------#
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

#----------------------------------------#
#         module SECURITY-GROUP          #
#----------------------------------------#

### maybe no need, re-enabled when you need
#output "security_group_name" {
#  description = "The name of the security group"
#  value       = module.complete_sg.security_group_name
#}
#
#output "security_group_description" {
#  description = "The description of the security group"
#  value       = module.complete_sg.security_group_description
#}

#----------------------------------------#
#    module RDS (Replica PostgreSQL)     #
#----------------------------------------#
### Master
output "master_db_instance_name" {
  description = "The database name"
  value       = module.rds.db_instance_name
  sensitive   = true
}

output "master_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rds.db_instance_address
}

output "master_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.rds.db_instance_endpoint
}

output "master_db_instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.db_instance_id
}

output "master_db_instance_status" {
  description = "The RDS instance status"
  value       = module.rds.db_instance_status
}

output "master_db_instance_username" {
  description = "The master username for the database"
  value       = module.rds.db_instance_username
  sensitive   = true
}

output "master_db_instance_password" {
  description = "The database password (this password may be old, because  Terraform doesn't track it after initial creation)"
  value       = module.rds.db_instance_password
  sensitive   = true
}

#----------------------------------------#
#           module DocumentDB            #
#----------------------------------------#
output "docdb_cluster_name" {
  value       = module.documentdb.cluster_name
  description = "DocumentDB Cluster Identifier"
}

output "docdb_endpoint" {
  value       = module.documentdb.endpoint
  description = "Endpoint of the DocumentDB cluster"
}

output "docdb_master_host" {
  value       = module.documentdb.master_host
  description = "DocumentDB master hostname"
}

output "docdb_replicas_host" {
  value       = module.documentdb.replicas_host
  description = "DocumentDB replicas hostname"
}

output "docdb_reader_endpoint" {
  value       = module.documentdb.reader_endpoint
  description = "Read-only endpoint of the DocumentDB cluster, automatically load-balanced across replicas"
}

#----------------------------------------#
#    module EC2 (devops-workspace)       #
#----------------------------------------#
output "ec2_ids" {
  description = "List of IDs of instances"
  value       = module.ec2.id
}

output "efs_id" {
  value = module.efs.id
}