output aws_access_key {
  description = "AWS access key"
  value       = data.vault_aws_access_credentials.creds.access_key
}

output aws_secret_key {
  description = "AWS secret key"
  value       = data.vault_aws_access_credentials.creds.secret_key
}

output aws_token {
  description = "AWS security token"
  value       = data.vault_aws_access_credentials.creds.security_token
}

output saas_postgres_password {
  value       =  data.vault_generic_secret.saas_secret.data["postgres_password"]
}

output saas_nosql_password {
  value       =  data.vault_generic_secret.saas_secret.data["nosql_password"]
}

output saas_es_password {
  value       =  data.vault_generic_secret.saas_secret.data["es_password"]
}

output saas_redis_password {
  value       =  data.vault_generic_secret.saas_secret.data["redis_password"]
}
