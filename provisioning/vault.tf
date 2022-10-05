#----------------------------------------------#
#     Authentication with Vault via AppRole    #
#----------------------------------------------#
provider "vault" {
  address         = var.vault_input.vault_endpoint
  token           = var.vault_terraformapprole_token
}

#----------------------------------------------#
#         Deploy aws_config_root & role        #
#             (vault-aws-engine)               #
#----------------------------------------------#
resource "vault_aws_secret_backend_role" "terraform_deployer" {
  backend         = "aws"
  name            = var.vault_input.vault_aws_backend_role_name
  credential_type = "assumed_role"
  role_arns       = var.vault_input.role_arns
  default_sts_ttl = var.vault_input.default_sts_ttl
}

data "vault_aws_access_credentials" "creds" {
  backend    = "aws"
  role       = var.vault_input.vault_aws_backend_role_name
  region     = var.global_input.region
  type       = "sts"
  depends_on = [ vault_aws_secret_backend_role.terraform_deployer ]
}

#----------------------------------------------#
#         Retrieve saas's credentials          #
#           (DBs password)                     # 
#----------------------------------------------#
data "vault_generic_secret" "saas_secret" {
  path = var.vault_input.infra_secret_path
}
