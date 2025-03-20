variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the input S3 bucket"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the output S3 bucket"
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

variable "lambda_trigger_role_arn" {
  description = "ARN of the IAM role for the Lambda trigger function"
  type        = string
}

variable "lambda_processor_role_arn" {
  description = "ARN of the IAM role for the Lambda processor functions"
  type        = string
}

variable "stepfunctions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  type        = string
}