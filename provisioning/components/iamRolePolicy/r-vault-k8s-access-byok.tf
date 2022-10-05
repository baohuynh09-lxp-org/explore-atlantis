#---------------------------------------------------#
#    3.Role/Policy for k8s-vault to access KMS      #
#---------------------------------------------------#
resource "aws_iam_user" "vault_k8s_kms" {
  name = "vault-k8s-kms"
  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-vault-k8s-kms"
  }
}

resource "aws_iam_user_policy" "vault_k8s_kms_policy" {
  name = "vault-k8s-kms-policy"
  user = aws_iam_user.vault_k8s_kms.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
      ],
      "Resource": "${var.global_input.BYOK}"
    }
  ]
}
EOF
  depends_on = [ aws_iam_user.vault_k8s_kms ]
}
