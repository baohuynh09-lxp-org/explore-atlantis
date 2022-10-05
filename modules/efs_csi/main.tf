resource "aws_iam_policy" "efs_csi_policy" {
  name      = "${var.customer}-${var.env}-AmazonEKS_EFS_CSI_Driver_Policy"
  path      = "/"
  description = "EFS CSI Policy"
  policy    = file("${path.module}/policy.json")
}

resource "aws_iam_role" "efs_csi_role" {
  name      = "${var.customer}-${var.env}-AmazonEKS_EFS_CSI_Role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : var.oidc_provider_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${var.oidc_provider_url}:sub" : "system:serviceaccount:${var.csi_namespace}:${var.csi_sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "efs_csi_attachment" {
  name = "${var.customer}-${var.env}-efs-policy"
  roles      = [aws_iam_role.efs_csi_role.name]
  policy_arn = aws_iam_policy.efs_csi_policy.arn
}

# Install aws-efs-csi-driver helm chart
resource "helm_release" "aws-efs-csi-driver" {
  depends_on = [
    aws_iam_role.efs_csi_role
  ]
  name = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart = "aws-efs-csi-driver"
  namespace = "kube-system"

  set {
    name = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/eks/aws-efs-csi-driver"
  }

  set {
    name = "controller.serviceAccount.create"
    value = true
  }

  set {
    name = "controller.serviceAccount.name"
    value = var.csi_sa_name
  }

  set {
    name = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_role.arn
  }
}
