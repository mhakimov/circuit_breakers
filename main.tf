locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}

module "network" {
  source               = "./modules/network"
  project              = var.project
  vpc_cidr             = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
  private_subnet_azs   = ["${var.aws_region}a", "${var.aws_region}b"]
  enable_eks_tags      = true
  tags                 = local.tags
  eks_cluster_name     = var.eks_cluster_name
}
