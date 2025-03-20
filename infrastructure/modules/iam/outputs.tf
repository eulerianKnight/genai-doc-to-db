output "lambda_trigger_role_arn" {
  description = "ARN of the Lambda Trigger Role"
  value       = aws_iam_role.lambda_trigger_role.arn
}

output "lambda_processor_role_arn" {
  description = "ARN of the Lambda Processor Role"
  value       = aws_iam_role.lambda_processor_role.arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "sfn_role_arn" {
  description = "ARN of the Step Functions State Machine Role"
  value       = aws_iam_role.sfn_role.arn
}