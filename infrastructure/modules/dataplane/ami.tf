data "aws_ami" "eks_worker_al2023" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-x86_64-standard-*"]
  }
  most_recent = true
  owners      = ["602401143452"]
}