output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.processing_cluster.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.processing_cluster.name
}

output "pdf_extract_task_arn" {
  description = "ARN of the PDF extraction task definition"
  value       = aws_ecs_task_definition.pdf_extract.arn
}

output "pdf_convert_task_arn" {
  description = "ARN of the PDF conversion task definition"
  value       = aws_ecs_task_definition.pdf_convert.arn
}

output "pdf_process_task_arn" {
  description = "ARN of the PDF processing task definition"
  value       = aws_ecs_task_definition.pdf_process.arn
}

output "excel_analyze_task_arn" {
  description = "ARN of the Excel analysis task definition"
  value       = aws_ecs_task_definition.excel_analyze.arn
}

output "excel_generate_task_arn" {
  description = "ARN of the Excel script generation task definition"
  value       = aws_ecs_task_definition.excel_generate.arn
}

output "excel_execute_task_arn" {
  description = "ARN of the Excel script execution task definition"
  value       = aws_ecs_task_definition.excel_execute.arn
}