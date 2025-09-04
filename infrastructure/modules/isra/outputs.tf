output "vpc_cni_role_arn" {
  value = aws_iam_role.iam_role_aws_node.arn
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}

output "aws_iam_oidc_arn" {
  value = aws_iam_openid_connect_provider.iam_oidc_provider_global.arn
}