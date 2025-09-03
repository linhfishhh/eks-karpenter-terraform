#iam for control plane
resource "aws_iam_role" "iam_role_eks_cluster" {
  name = "eks_role_cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "role_policy-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.iam_role_eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "role_policy-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.iam_role_eks_cluster.name
}


#iam role for data plane
resource "aws_iam_role" "iam_role_eks_node_group" {
  name = "eks_role_node_group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_role_policy_attachment" "role_policy-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.iam_role_eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "role_policy-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.iam_role_eks_node_group.name
}


resource "aws_iam_instance_profile" "instance_profile_eks_asg" {
  name = "instance_profile_eks_asg"
  role = aws_iam_role.iam_role_eks_node_group.name
}
