locals {
  nodepool_core_subnet = {
    subnets = module.vpc.private_subnets
  }
  nodepool_voip_subnet = {
    subnets = module.vpc.public_subnets
  }
  use_nodepool_voip = contains(
    keys(var.eks_input.node_groups),
    "nodepool_voip")

  nodepool_core = {
    nodepool_core = merge(
      var.eks_input.node_groups.nodepool_core,
      local.nodepool_core_subnet
    )
  }

  nodepool_voip = local.use_nodepool_voip ? {
    nodepool_voip = merge(
      var.eks_input.node_groups.nodepool_voip,
      local.nodepool_voip_subnet
    )
  } : null
}