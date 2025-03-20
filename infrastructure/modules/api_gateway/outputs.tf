output "api_endpoint" {
  description = "Endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.upload_api.api_endpoint
}

output "upload_url" {
  description = "URL for the upload endpoint"
  value       = "${aws_apigatewayv2_stage.upload_stage.invoke_url}/upload"
}

output "presigned_url_endpoint" {
  description = "URL for the presigned URL generation endpoint"
  value       = "${aws_apigatewayv2_stage.upload_stage.invoke_url}/generate-presigned-url"
}