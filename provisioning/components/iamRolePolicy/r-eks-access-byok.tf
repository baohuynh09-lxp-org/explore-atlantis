#---------------------------------------------------#
#          1.EKS access BYOK for encryption         #
#                  (k8s secret)                     #
#---------------------------------------------------#
resource "aws_iam_role" "eks_role" {
  name = "${var.global_input.customer}_eks_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "EKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

# AmazonEKSVPCResourceController:
# used by VPC Resource Controller to manage ENI and IPs for worker nodes
# ==> detach/attach static IP for VOIP workers
resource "aws_iam_role_policy_attachment" "EKSVPCResourceController" {
  count      = local.use_nodepool_voip ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

resource "aws_kms_grant" "BYOK_access_grant" {
  name              = "BYOK_access_grant"
  key_id            = "${var.global_input.BYOK}"
  grantee_principal = aws_iam_role.eks_role.arn
  operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
}

