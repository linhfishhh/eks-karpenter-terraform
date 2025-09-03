output "karpenter_interruption_queue_arn" {
  description = "ARN of the Karpenter interruption queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.arn
}

output "karpenter_interruption_queue_name" {
  description = "Name of the Karpenter interruption queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.name
}

output "karpenter_interruption_queue_url" {
  description = "URL of the Karpenter interruption queue"
  value       = aws_sqs_queue.karpenter_interruption_queue.id
}