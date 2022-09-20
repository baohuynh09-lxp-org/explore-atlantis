#---------------------------------------------------#
#    RDS: NACL for "private" to access "database"   #
#---------------------------------------------------#
resource "aws_network_acl" "database_network_acl" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = "${data.aws_subnet_ids.database.ids}"
  tags = {
    env   = var.env
    site  = "${var.customer}-${var.env}-${var.region}"
    Name  = "${var.customer}-${var.env}-private-access-db"
  }
}

resource "aws_network_acl_rule" "database_inbound" {
  for_each = {
    # Use 'setproduct' to produce combination of [port+private_subnet_cidr] block
    for item in setproduct(var.vpc_input.list_port_db_access,module.vpc.private_subnets_cidr_blocks) : "${item[0]}-${item[1]}" => {
      database_access_port = item[0]
      private_subnet_cidr  = item[1]
      list_index           = index(setproduct(var.vpc_input.list_port_db_access,module.vpc.private_subnets_cidr_blocks),[item[0],item[1]])
    }
  }

  network_acl_id = aws_network_acl.database_network_acl.id
  protocol       = "tcp"
  rule_number    = "${each.value.list_index}" + 100
  rule_action    = "allow"
  cidr_block     = each.value.private_subnet_cidr
  from_port      = each.value.database_access_port
  to_port        = each.value.database_access_port
}

resource "aws_network_acl_rule" "database_outbound" {
  count          = length(module.vpc.private_subnets_cidr_blocks)
  network_acl_id = aws_network_acl.database_network_acl.id


  egress         = "true"
  protocol       = "tcp"
  rule_number    = "20${count.index}"
  rule_action    = "allow"
  cidr_block     = module.vpc.private_subnets_cidr_blocks[count.index]
  from_port      = 0
  to_port        = 65535
}