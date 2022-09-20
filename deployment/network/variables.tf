#---------------------------------------#
#               GLOBAL                  #
#---------------------------------------#
variable "customer" {
  type        = string
  description = "The customer.Ex:Macquarie"
}

variable "env" {
  type        = string
  description = "The environment.Ex:prod-saas"
}

variable "region" {
  type = string
  description = "AWS Region"
}

variable "BYOK" {
  type        = string
  description = "ARN of BYOK encrypted key from customer"
}

variable "KMS_vault_autounseal" {
  type        = string
  description = "ARN of KMS_vault_autounseal"
}

variable "AWS_ACCOUNT_ID" {
  type        = string
  description = "AWS account ID"
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