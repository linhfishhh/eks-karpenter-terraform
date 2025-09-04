variable "environment" {
  
}

variable "eks_oidc_url" {
  
}

variable "eks_oidc_arn" {
}


resource "aws_s3_bucket" "devops" {
  bucket = "devops.linhfish.dev"

  tags = {
    Name = "s3_linhfish_devops"
    Environment = var.environment
  }
}

// policy for DevOps bucket
data "aws_iam_policy_document" "iam_policy_document_devops" {
  statement {
    sid = "1"
    actions = ["s3:*"]
    resources = ["${aws_s3_bucket.devops.arn}/*", aws_s3_bucket.devops.arn]
  }
}

resource "aws_iam_policy" "iam_policy_devops" {
  name = "eks_policy_linhfish_devops"
  policy = data.aws_iam_policy_document.iam_policy_document_devops.json
}

data "aws_iam_policy_document" "iam_policy_document_assume_devops" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test = "StringEquals"
      variable = "${var.eks_oidc_url}:aud"
      values = ["sts.amazonaws.com"]
    }

    principals {
      type = "Federated"
      identifiers = [var.eks_oidc_arn]
    }
  }
}

resource "aws_iam_role" "iam_role_devops" {
  name = "eks_linhfish_devops"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document_assume_devops.json
}

resource "aws_iam_role_policy_attachment" "iam_policy_attachment_devops" {
  role = aws_iam_role.iam_role_devops.name
  policy_arn = aws_iam_policy.iam_policy_devops.arn
}
