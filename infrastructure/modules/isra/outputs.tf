output "vpc_cni_role_arn" {
  value = aws_iam_role.iam_role_aws_node.arn
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}