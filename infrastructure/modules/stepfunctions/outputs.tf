output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.document_processing.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.document_processing.name
}

output "security_group_id" {
  description = "ID of the security group used for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}