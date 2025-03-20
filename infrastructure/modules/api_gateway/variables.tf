variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "upload_lambda_arn" {
  description = "ARN of the Lambda function for file uploads"
  type        = string
}

variable "upload_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for file uploads"
  type        = string
}

variable "presigned_url_lambda_arn" {
  description = "ARN of the Lambda function for generating presigned URLs"
  type        = string
  default     = ""
}

variable "presigned_url_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function for generating presigned URLs"
  type        = string
  default     = ""
}