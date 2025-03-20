output "input_bucket_id" {
  description = "ID of the input S3 bucket"
  value       = aws_s3_bucket.input_bucket.id
}

output "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
  value       = aws_s3_bucket.input_bucket.arn
}

output "input_bucket_name" {
  description = "Name of the input S3 bucket"
  value       = aws_s3_bucket.input_bucket.bucket
}

output "output_bucket_id" {
  description = "ID of the output S3 bucket"
  value       = aws_s3_bucket.output_bucket.id
}

output "output_bucket_arn" {
  description = "ARN of the output S3 bucket"
  value       = aws_s3_bucket.output_bucket.arn
}

output "output_bucket_name" {
  description = "Name of the output S3 bucket"
  value       = aws_s3_bucket.output_bucket.bucket
}

output "data_model_bucket_id" {
  description = "ID of the data model S3 bucket"
  value       = aws_s3_bucket.data_model_bucket.id
}

output "data_model_bucket_arn" {
  description = "ARN of the data model S3 bucket"
  value       = aws_s3_bucket.data_model_bucket.arn
}

output "data_model_bucket_name" {
  description = "Name of the data model S3 bucket"
  value       = aws_s3_bucket.data_model_bucket.bucket
}