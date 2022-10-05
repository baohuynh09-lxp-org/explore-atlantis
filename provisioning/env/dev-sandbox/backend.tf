region         = "us-west-2"
bucket         = "lxp-enterprise-saas-uswest2-tf"
key            = "lxp-enterprise-saas-uswest2-tf.tfstate"

encrypt        = "true"

# Using locking state with dynamoDB
dynamodb_table = "terraform-state-lock"
access_key     = "AKIAXIHC3QJUXKEW7XSX"
secret_key     = "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"
