
module "vpc" {
  source       = "./modules/networking/vpc"
  cluster_name = var.cluster_name
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids
}

