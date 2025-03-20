locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create API Gateway for file uploads
resource "aws_apigatewayv2_api" "upload_api" {
  name          = "${local.name_prefix}-upload-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins     = ["*"] # Restrict to your application domains in production
    allow_methods     = ["POST", "OPTIONS"]
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    expose_headers    = ["content-disposition", "content-type"]
    allow_credentials = true
    max_age           = 300
  }
}

# Create API Gateway stage
resource "aws_apigatewayv2_stage" "upload_stage" {
  api_id      = aws_apigatewayv2_api.upload_api.id
  name        = "$default"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      responseLatency = "$context.responseLatency"
    })
  }
}

# Integration for file upload Lambda
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id                 = aws_apigatewayv2_api.upload_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.upload_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route for file upload
resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.upload_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}

# Integration for presigned URL Lambda
resource "aws_apigatewayv2_integration" "presigned_url_integration" {
  api_id                 = aws_apigatewayv2_api.upload_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.presigned_url_lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route for generating presigned URLs
resource "aws_apigatewayv2_route" "presigned_url_route" {
  api_id    = aws_apigatewayv2_api.upload_api.id
  route_key = "POST /generate-presigned-url"
  target    = "integrations/${aws_apigatewayv2_integration.presigned_url_integration.id}"
}

# Permission for API Gateway to invoke the Lambda functions
resource "aws_lambda_permission" "api_gateway_upload" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_arn
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_apigatewayv2_api.upload_api.execution_arn}/*/*/upload"
}

resource "aws_lambda_permission" "api_gateway_presigned_url" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.presigned_url_lambda_arn
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_apigatewayv2_api.upload_api.execution_arn}/*/*/generate-presigned-url"
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}-upload-api"
  retention_in_days = 30
}