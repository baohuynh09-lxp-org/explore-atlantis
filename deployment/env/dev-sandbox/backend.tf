region         = "us-west-2"
bucket         = "lxp-enterprise-saas-uswest2-tf"
key            = "lxp-enterprise-saas-uswest2-tf.tfstate"

encrypt        = "true"

# Using locking state with dynamoDB
dynamodb_table = "terraform-state-lock"

