#--------------------------------------#
#            VPC: Elastic IP           #
#--------------------------------------#
# Create separated EIP to avoid destroying VPC alongside with EIP
resource "aws_eip" "nat_public_ip" {
  count = 1
  vpc = true
  tags = {
    env   = "${var.env}"
    site  = "${var.customer}-${var.env}-${var.region}"
    Name  = "${var.customer}-${var.env}-eip-nat"
  }
}

resource "aws_eip" "istio_ingress_public_ip" {
  count = 1
  vpc = true
  tags = {
    env   = "${var.env}"
    site  = "${var.customer}-${var.env}-${var.region}"
    Name  = "${var.customer}-${var.env}-eip-istio-ingress"
  }
}

# EIP for EKS nodepool_voip workers
resource "aws_eip" "nodepool_voip_worker" {
  count = "${var.eks_input.node_groups.nodepool_voip.max_capacity}"
  vpc = true
  tags = {
    env           = "${var.env}"
    site          = "${var.customer}-${var.env}-${var.region}"
    Name          = "${var.customer}-${var.env}-eip-nat"
    nodepool_voip = true
  }
}