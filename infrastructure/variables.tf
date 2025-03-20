variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "doc-processing"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "input_bucket_name" {
  description = "Name for the S3 bucket where files are uploaded"
  type        = string
  default     = null # Will use a generated name if not specified
}

variable "output_bucket_name" {
  description = "Name for the S3 bucket where processed CSV files are stored"
  type        = string
  default     = null # Will use a generated name if not specified
}

variable "data_model_bucket_name" {
  description = "Name for the S3 bucket where data models are stored"
  type        = string
  default     = null # Will use a generated name if not specified
}

variable "ecr_repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = [
    "pdf-extract",
    "pdf-convert",
    "pdf-process",
    "excel-analyze",
    "excel-generate",
    "excel-execute"
  ]
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model ID for Claude"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}