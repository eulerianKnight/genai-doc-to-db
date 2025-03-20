output "trigger_lambda_arn" {
  description = "ARN of the Lambda function that triggers the Step Functions workflow"
  value       = aws_lambda_function.trigger_lambda.arn
}

output "upload_lambda_arn" {
  description = "ARN of the Lambda function that handles API uploads"
  value       = aws_lambda_function.upload_lambda.arn
}

output "upload_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function that handles API uploads"
  value       = aws_lambda_function.upload_lambda.invoke_arn
}

output "presigned_url_lambda_arn" {
  description = "ARN of the Lambda function that generates presigned URLs"
  value       = aws_lambda_function.presigned_url_lambda.arn
}

output "presigned_url_lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function that generates presigned URLs"
  value       = aws_lambda_function.presigned_url_lambda.invoke_arn
}

output "trigger_lambda_permission" {
  description = "Permission for S3 to invoke the trigger Lambda"
  value       = aws_lambda_permission.allow_bucket
}