locals {
  name   = var.name
  region = var.region
  eks_public_cluster_endpoint = var.eks_public_cluster_endpoint

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = merge(var.tags, {
    Blueprint  = local.name
  })
}