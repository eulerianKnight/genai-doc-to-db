variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "sfn_role_arn" {
  description = "ARN of the IAM role for the Step Functions state machine"
  type        = string
}

variable "pdf_extract_task_arn" {
  description = "ARN of the ECS task definition for PDF extraction"
  type        = string
}

variable "pdf_convert_task_arn" {
  description = "ARN of the ECS task definition for PDF to image conversion"
  type        = string
}

variable "pdf_process_task_arn" {
  description = "ARN of the ECS task definition for PDF processing with Bedrock"
  type        = string
}

variable "excel_analyze_task_arn" {
  description = "ARN of the ECS task definition for Excel analysis"
  type        = string
}

variable "excel_generate_task_arn" {
  description = "ARN of the ECS task definition for generating Python scripts"
  type        = string
}

variable "excel_execute_task_arn" {
  description = "ARN of the ECS task definition for executing generated scripts"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}