locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# CloudWatch Dashboard for the document processing pipeline
resource "aws_cloudwatch_dashboard" "document_processing_dashboard" {
  dashboard_name = "${local.name_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # Step Functions Execution Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineArn", var.state_machine_arn],
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", var.state_machine_arn],
            ["AWS/States", "ExecutionsFailed", "StateMachineArn", var.state_machine_arn],
            ["AWS/States", "ExecutionsTimedOut", "StateMachineArn", var.state_machine_arn]
          ]
          region = var.aws_region
          title  = "Step Functions Executions"
        }
      },
      
      # ECS Cluster Metrics
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name]
          ]
          region = var.aws_region
          title  = "ECS Cluster Utilization"
        }
      },
      
      # S3 Input Bucket Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", var.input_bucket_name, "StorageType", "AllStorageTypes"],
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.input_bucket_name, "StorageType", "StandardStorage"]
          ]
          region = var.aws_region
          title  = "S3 Input Bucket"
        }
      },
      
      # S3 Output Bucket Metrics
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", var.output_bucket_name, "StorageType", "AllStorageTypes"],
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.output_bucket_name, "StorageType", "StandardStorage"]
          ]
          region = var.aws_region
          title  = "S3 Output Bucket"
        }
      },
      
      # Lambda Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.trigger_lambda_name],
            ["AWS/Lambda", "Errors", "FunctionName", var.trigger_lambda_name],
            ["AWS/Lambda", "Duration", "FunctionName", var.trigger_lambda_name]
          ]
          region = var.aws_region
          title  = "Lambda Trigger Function"
        }
      },
      
      # API Gateway Metrics
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id],
            ["AWS/ApiGateway", "4XXError", "ApiId", var.api_gateway_id],
            ["AWS/ApiGateway", "5XXError", "ApiId", var.api_gateway_id],
            ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id]
          ]
          region = var.aws_region
          title  = "API Gateway"
        }
      }
    ]
  })
}

# Step Functions Execution Failed Alarm
resource "aws_cloudwatch_metric_alarm" "step_functions_execution_failed" {
  alarm_name          = "${local.name_prefix}-sfn-execution-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 2
  alarm_description   = "This alarm monitors for Step Functions execution failures"
  
  dimensions = {
    StateMachineArn = var.state_machine_arn
  }
  
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# ECS Task Failed Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_task_failed" {
  alarm_name          = "${local.name_prefix}-ecs-task-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This alarm monitors for ECS task failures"
  
  dimensions = {
    ClusterName = var.cluster_name
  }
  
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# API Gateway 5XX Error Alarm
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_error" {
  alarm_name          = "${local.name_prefix}-api-5xx-error"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This alarm monitors for API Gateway 5XX errors"
  
  dimensions = {
    ApiId = var.api_gateway_id
  }
  
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# Optional SNS Topic for Alarms (only created if sns_topic_arn is not provided)
resource "aws_sns_topic" "alarms_topic" {
  count = var.sns_topic_arn == "" ? 1 : 0
  
  name = "${local.name_prefix}-alarms-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count = var.sns_topic_arn == "" && var.alarm_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alarms_topic[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}