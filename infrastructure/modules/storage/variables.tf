variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "input_bucket_name" {
  description = "Name for the S3 bucket where files are uploaded"
  type        = string
  default     = null
}

variable "output_bucket_name" {
  description = "Name for the S3 bucket where processed CSV files are stored"
  type        = string
  default     = null
}

variable "data_model_bucket_name" {
  description = "Name for the S3 bucket where data models are stored"
  type        = string
  default     = null
}