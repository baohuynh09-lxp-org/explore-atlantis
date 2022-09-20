#---------------------------------------------------#
#            BYOK access grant to EKS               #
#---------------------------------------------------#
resource "aws_iam_role" "eks_role" {
  name = "${var.customer}_eks_role"

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
  depends_on = [aws_iam_role.eks_role]
}

# AmazonEKSVPCResourceController:
# used by VPC Resource Controller to manage ENI and IPs for worker nodes
# ==> detach/attach static IP for VOIP workers
resource "aws_iam_role_policy_attachment" "EKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
  depends_on = [aws_iam_role.eks_role]
}

resource "aws_kms_grant" "BYOK_access_grant" {
  name              = "BYOK_access_grant"
  key_id            = "${var.BYOK}"
  grantee_principal = aws_iam_role.eks_role.arn
  operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
  depends_on = [
    aws_iam_role_policy_attachment.EKSClusterPolicy,
    aws_iam_role_policy_attachment.EKSVPCResourceController
  ]
}
