output "control_plane_role_arn" {
    value = aws_iam_role.iam_role_eks_cluster.arn
}

output "instance_profile_name" {
    value = aws_iam_instance_profile.instance_profile_eks_asg.name
}

output "node_group_role_arn" {
    value = aws_iam_role.iam_role_eks_node_group.arn
  
}