resource "aws_iam_user" "eks_attach_staticip_nodepool_voip" {
  name = "eks-attach-staticip-nodepool-voip"
  tags = {
    env    = "${var.customer}-${var.env}"
    site   = "${var.customer}-${var.env}-${var.region}"
    Name   = "${var.customer}-${var.env}-"
  }
}

resource "aws_iam_user_policy" "eks_attach_staticip_nodepool_voip_policy" {
  name = "eks-attach-staticip-nodepool-voip-policy"
  user = aws_iam_user.eks_attach_staticip_nodepool_voip.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  depends_on = [ aws_iam_user.eks_attach_staticip_nodepool_voip ]
}