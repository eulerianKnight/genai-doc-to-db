output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.document_processing_dashboard.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = var.sns_topic_arn != "" ? var.sns_topic_arn : (length(aws_sns_topic.alarms_topic) > 0 ? aws_sns_topic.alarms_topic[0].arn : null)
}