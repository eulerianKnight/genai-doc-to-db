locals {
  name_prefix = "${var.project_name}-${var.environment}"
  lambda_src_dir = "${path.module}/lambda_src"
}

# Lambda function to trigger the Step Functions workflow from S3 events
resource "aws_lambda_function" "trigger_lambda" {
  function_name    = "${local.name_prefix}-trigger-lambda"
  role             = var.lambda_trigger_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  
  filename         = "${local.lambda_src_dir}/trigger_lambda.zip"
  source_code_hash = filebase64sha256("${local.lambda_src_dir}/trigger_lambda.zip")
  
  environment {
    variables = {
      STATE_MACHINE_ARN = var.stepfunctions_state_machine_arn
      INPUT_BUCKET      = var.input_bucket_name
      OUTPUT_BUCKET     = var.output_bucket_name
      DATA_MODEL_BUCKET = var.data_model_bucket_name
    }
  }

  // Note: In a real deployment, you would use a proper deployment package
  // The placeholder zip file is used here for illustration
  // Ideally this would be provided by your CI/CD pipeline
}

# Permission for S3 to invoke the trigger Lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.input_bucket_arn
}

# Lambda function to handle API uploads
resource "aws_lambda_function" "upload_lambda" {
  function_name    = "${local.name_prefix}-upload-lambda"
  role             = var.lambda_processor_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  
  filename         = "${local.lambda_src_dir}/upload_lambda.zip"
  source_code_hash = filebase64sha256("${local.lambda_src_dir}/upload_lambda.zip")
  
  environment {
    variables = {
      INPUT_BUCKET      = var.input_bucket_name
      UPLOAD_PREFIX     = "uploads/api/"
    }
  }

  // Note: In a real deployment, you would use a proper deployment package
  // The placeholder zip file is used here for illustration
}

# Lambda function to generate presigned URLs
resource "aws_lambda_function" "presigned_url_lambda" {
  function_name    = "${local.name_prefix}-presigned-url-lambda"
  role             = var.lambda_processor_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  
  filename         = "${local.lambda_src_dir}/presigned_url_lambda.zip"
  source_code_hash = filebase64sha256("${local.lambda_src_dir}/presigned_url_lambda.zip")
  
  environment {
    variables = {
      INPUT_BUCKET      = var.input_bucket_name
      UPLOAD_PREFIX     = "uploads/direct/"
      URL_EXPIRATION    = "3600"  # 1 hour
    }
  }

  // Note: In a real deployment, you would use a proper deployment package
  // The placeholder zip file is used here for illustration
}

# Example CloudWatch Log Groups for Lambda functions with retention policy
resource "aws_cloudwatch_log_group" "trigger_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "upload_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "presigned_url_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.presigned_url_lambda.function_name}"
  retention_in_days = 30
}