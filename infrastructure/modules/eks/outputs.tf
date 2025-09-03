output "cluster_sg_id" {
    value = aws_eks_cluster.global_cluster.vpc_config[0].cluster_security_group_id
}

output "oidc_url" {
    value = trimprefix(aws_eks_cluster.global_cluster.identity[0].oidc[0].issuer, "https://")
}

output "eks_cluster_endpoint" {
    value = aws_eks_cluster.global_cluster.endpoint
}

output "eks_cluster_ca" {
    value = aws_eks_cluster.global_cluster.certificate_authority[0].data
}

