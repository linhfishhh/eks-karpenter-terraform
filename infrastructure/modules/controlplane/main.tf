

resource "aws_eks_cluster" "global_cluster" {
    name = var.eks.name
    version = var.eks.version
    role_arn = var.eks.control_plane_role_arn

    vpc_config {
      subnet_ids = concat(var.eks.private_subnet_ids, var.eks.public_subnet_ids)
      endpoint_private_access = true
      endpoint_public_access = true
    }
    
    tags = {
      Role = "eks_cluster"
      Environment = var.environment
    }

    access_config {
      authentication_mode = "API_AND_CONFIG_MAP"
    }
}

data "aws_caller_identity" "current" {
  
}

resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.global_cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.global_cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "node_group" {
  cluster_name  = aws_eks_cluster.global_cluster.name
  principal_arn = var.eks.node_group_role_arn
  type          = "EC2_LINUX"
}
