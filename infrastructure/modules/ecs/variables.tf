variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
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

variable "ecs_task_role_arn" {
  description = "ARN of the IAM role for ECS tasks"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  type        = string
}

variable "ecr_repository_urls" {
  description = "Map of ECR repository URLs for container images"
  type        = map(string)
}

variable "input_bucket_name" {
  description = "Name of the input S3 bucket"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the output S3 bucket"
  type        = string
}

variable "data_model_bucket_name" {
  description = "Name of the data model S3 bucket"
  type        = string
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model ID for Claude"
  type        = string
}