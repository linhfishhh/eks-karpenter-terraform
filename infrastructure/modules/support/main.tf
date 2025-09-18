resource "aws_sqs_queue" "karpenter_interruption_queue" {
    name =  var.eks_clsuter_name
    message_retention_seconds = 300
    sqs_managed_sse_enabled = true

    tags = {
        Name = "${var.eks_clsuter_name}-karpenter-interruption-queue"
        Environment = var.environment
    }
  
}

data "aws_iam_policy_document" "karpenter_interruption_queue" {
  statement {
    sid     = "EC2InterruptionPolicy"
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption_queue.arn]
  }

  statement {
    sid     = "DenyHTTP"
    effect  = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.karpenter_interruption_queue.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
    queue_url = aws_sqs_queue.karpenter_interruption_queue.id

    policy = data.aws_iam_policy_document.karpenter_interruption_queue.json
  
}


resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name = "${var.eks_clsuter_name}-scheduled-change-rule"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = {
    Name = "${var.eks_clsuter_name}-scheduled-change-rule"
    environment = var.environment
  }
}


resource "aws_cloudwatch_event_target" "scheduled_change_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name = "${var.eks_clsuter_name}-spot-interruption-rule"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = {
    Name = "${var.eks_clsuter_name}-spot-interruption-rule"
  }
}


resource "aws_cloudwatch_event_target" "spot_interruption_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}


resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name = "${var.eks_clsuter_name}-rebalance-rule"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = {
    Name = "${var.eks_clsuter_name}-rebalance-rule"
  }
}


resource "aws_cloudwatch_event_target" "rebalance_target" {
  rule      = aws_cloudwatch_event_rule.rebalance_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}


resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name = "${var.eks_clsuter_name}-instance-state-change-rule"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })

  tags = {
    Name = "${var.eks_clsuter_name}-instance-state-change-rule"
  }
}

resource "aws_cloudwatch_event_target" "instance_state_change_target" {
  rule      = aws_cloudwatch_event_rule.instance_state_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}


resource "aws_ecr_repository" "ecr_repositories" {
  for_each = toset(var.repositories)
  name = each.value
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_repositories_lifecycle_policy" {
  for_each = toset(var.repositories)
  repository = each.value

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Auto removal of all un-tagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

  depends_on = [
    aws_ecr_repository.ecr_repositories
  ]
}