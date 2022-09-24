#---------------------------------------------------#
#    4.Attach static pulblic IP for VOIP nodepool   #
#---------------------------------------------------#
resource aws_iam_user "eks_attach_staticip_nodepool_voip" {
  name = "eks-attach-staticip-nodepool-voip"
  tags = {
    env    = "${var.global_input.customer}-${var.global_input.env}"
    site   = "${var.global_input.customer}-${var.global_input.env}-${var.global_input.region}"
    Name   = "${var.global_input.customer}-${var.global_input.env}-"
  }
}

resource aws_iam_user_policy "eks_attach_staticip_nodepool_voip_policy" {
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
}
