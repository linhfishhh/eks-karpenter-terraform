data "tls_certificate" "aws_oidc" {
  url = "https://${var.eks_oidc_url}/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "iam_oidc_provider_global" {
  url             = "https://${var.eks_oidc_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.aws_oidc.certificates[0].sha1_fingerprint]
}


#policy for VPC CNI
data "aws_iam_policy_document" "iam_policy_document_assume_aws_node" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.iam_oidc_provider_global.arn]
    }
  }
}

resource "aws_iam_role" "iam_role_aws_node" {
  name               = "eks_aws_node"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_assume_aws_node.json
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment_aws_node" {
  role       = aws_iam_role.iam_role_aws_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


#policy for EBS CSI driver
resource "aws_iam_policy" "iam_policy_aws_ebs_csi" {
  name   = "eks_policy_ebs_csi"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "iam_policy_document_assume_aws_ebs_csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.iam_oidc_provider_global.arn]
    }
  }
}

resource "aws_iam_role" "iam_role_aws_ebs_csi" {
  name               = "eks_aws_ebs_csi"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_assume_aws_ebs_csi.json
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment_aws_ebs_csi" {
  role       = aws_iam_role.iam_role_aws_ebs_csi.name
  policy_arn = aws_iam_policy.iam_policy_aws_ebs_csi.arn
}

#policy for karpenter
data "aws_caller_identity" "current" {}


data "aws_iam_policy_document" "karpenter_ec2_policy" {
  statement {
    sid = "EC2InstanceActions"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ec2:CreateTags"
    ]
  }

  statement {
    sid       = "EC2ReadActions"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:Describe*", "pricing:GetProducts"]
  }

  statement {
    sid    = "SSMAccess"
    effect = "Allow"
    resources = ["arn:aws:ssm:${var.region}::parameter/aws/service/*"]
    actions = ["ssm:GetParameter"]
  }
}

# Policy 2: IAM and EKS
data "aws_iam_policy_document" "karpenter_iam_policy" {
  statement {
    sid    = "PassRole"
    effect = "Allow"
    resources = [var.karpenter_node_role_arn]
    actions = ["iam:PassRole"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid    = "InstanceProfileActions"
    effect = "Allow"
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"]
    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile", 
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile"
    ]
  }

  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    resources = ["arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.eks_clsuter_name}"]
    actions   = ["eks:DescribeCluster"]
  }

  statement {
    sid    = "SQSAccess"
    effect = "Allow"
    resources = [var.karpenter_queue_arn]
    actions = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"]
  }
}

# Tạo các managed policies
resource "aws_iam_policy" "karpenter_ec2_policy" {
  name   = "KarpenterEC2Policy-${var.eks_clsuter_name}"
  policy = data.aws_iam_policy_document.karpenter_ec2_policy.json
}

resource "aws_iam_policy" "karpenter_iam_policy" {
  name   = "KarpenterIAMPolicy-${var.eks_clsuter_name}"
  policy = data.aws_iam_policy_document.karpenter_iam_policy.json
}

data "aws_iam_policy_document" "iam_policy_document_assume_karpenter_controller" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_url}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter-controller-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.iam_oidc_provider_global.arn]
    }
  }
}

resource "aws_iam_role" "karpenter_controller_role" {
  name = "karpenter_controller_role"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_assume_karpenter_controller.json
}

resource "aws_iam_role_policy_attachment" "karpenter_ec2_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "karpenter_iam_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_iam_policy.arn
}