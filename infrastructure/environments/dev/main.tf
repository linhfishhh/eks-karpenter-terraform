
module "iam" {
  source = "../../modules/iam"
}


module "vpc" {
  source             = "../../modules/vpc"
  cluster_name       = var.eks.name
  environment        = var.environment
  vpc_cidr           = var.vpc.vpc_cidr
  availability_zones = var.vpc.availability_zones
}

module "controlplane" {
  source      = "../../modules/eks"
  environment = var.environment
  eks = {
    name                   = var.eks.name
    version                = var.eks.version
    public_subnet_ids      = module.vpc.public_subnet_ids
    private_subnet_ids     = module.vpc.private_subnet_ids
    control_plane_role_arn = module.iam.control_plane_role_arn
    node_group_role_arn    = module.iam.node_group_role_arn
  }
}


module "support" {
  source           = "../../modules/support"
  environment      = var.environment
  eks_clsuter_name = var.eks.name

}

module "isra" {
  source           = "../../modules/isra"
  environment      = var.environment
  eks_oidc_url     = module.controlplane.oidc_url
  eks_clsuter_name = var.eks.name
  region           = var.region
  karpenter_node_role_arn = module.iam.node_group_role_arn
  karpenter_queue_arn = module.support.karpenter_interruption_queue_arn

}

module "dataplane" {
  source      = "../../modules/dataplane"
  environment = var.environment
  dataplane = {
    cluster_name         = var.eks.name
    iam_instance_profile = module.iam.instance_profile_name
    instance_type        = var.dataplane.instance_type
    private_subnet_ids   = module.vpc.private_subnet_ids
    sg_ids               = [module.controlplane.cluster_sg_id, module.vpc.global_sg_id]
    private_subnet_zones = var.vpc.availability_zones
    vpc_cidr             = var.vpc.vpc_cidr
  }

  eks_cluster_endpoint = module.controlplane.eks_cluster_endpoint
  eks_cluster_ca       = module.controlplane.eks_cluster_ca
}

