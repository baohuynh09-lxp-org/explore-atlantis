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
