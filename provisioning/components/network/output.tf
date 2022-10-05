output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnets in VPC"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnets in VPC"
  value       = module.vpc.private_subnets
}

output "database_subnet_group_name" {
  description = "database subnet group name"
  value       = module.vpc.database_subnet_group_name
}

output "security_group_ids_private_access_db" {
  description = "ID security group private-access-db"
  value       = data.aws_security_groups.private_access_db.ids
}

output "private_subnets_ids" {
  description = "IDs of private subnets in VPC"
  value       = data.aws_subnets.private.ids
}

output "database_subnets_ids" {
  description = "IDs of database subnets in VPC"
  value       = data.aws_subnets.database.ids
}