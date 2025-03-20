locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create ECS Cluster
resource "aws_ecs_cluster" "processing_cluster" {
  name = "${local.name_prefix}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Add CloudWatch Log group for the cluster
resource "aws_cloudwatch_log_group" "ecs_cluster_logs" {
  name              = "/aws/ecs/${local.name_prefix}-cluster"
  retention_in_days = 30
}

# Task Definitions for each processing step

# PDF Extract Task
resource "aws_ecs_task_definition" "pdf_extract" {
  family                   = "${local.name_prefix}-pdf-extract"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "pdf-extract"
      image     = "${var.ecr_repository_urls["pdf-extract"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["pdf-extract"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "pdf-extract"
        }
      }
    }
  ])
}

# PDF Convert Task
resource "aws_ecs_task_definition" "pdf_convert" {
  family                   = "${local.name_prefix}-pdf-convert"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"  # More resources for image conversion
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "pdf-convert"
      image     = "${var.ecr_repository_urls["pdf-convert"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["pdf-convert"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "pdf-convert"
        }
      }
    }
  ])
}

# PDF Process with Bedrock Task
resource "aws_ecs_task_definition" "pdf_process" {
  family                   = "${local.name_prefix}-pdf-process"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "pdf-process"
      image     = "${var.ecr_repository_urls["pdf-process"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        },
        {
          name  = "DATA_MODEL_BUCKET"
          value = var.data_model_bucket_name
        },
        {
          name  = "BEDROCK_MODEL_ID"
          value = var.bedrock_model_id
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["pdf-process"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "pdf-process"
        }
      }
    }
  ])
}

# Excel Analyze Task
resource "aws_ecs_task_definition" "excel_analyze" {
  family                   = "${local.name_prefix}-excel-analyze"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "excel-analyze"
      image     = "${var.ecr_repository_urls["excel-analyze"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["excel-analyze"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "excel-analyze"
        }
      }
    }
  ])
}

# Excel Generate Script Task
resource "aws_ecs_task_definition" "excel_generate" {
  family                   = "${local.name_prefix}-excel-generate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "excel-generate"
      image     = "${var.ecr_repository_urls["excel-generate"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        },
        {
          name  = "DATA_MODEL_BUCKET"
          value = var.data_model_bucket_name
        },
        {
          name  = "BEDROCK_MODEL_ID"
          value = var.bedrock_model_id
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["excel-generate"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "excel-generate"
        }
      }
    }
  ])
}

# Excel Execute Script Task
resource "aws_ecs_task_definition" "excel_execute" {
  family                   = "${local.name_prefix}-excel-execute"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  
  container_definitions = jsonencode([
    {
      name      = "excel-execute"
      image     = "${var.ecr_repository_urls["excel-execute"]}:latest"
      essential = true
      
      environment = [
        {
          name  = "INPUT_BUCKET"
          value = var.input_bucket_name
        },
        {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.container_logs["excel-execute"].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "excel-execute"
        }
      }
    }
  ])
}

# Create CloudWatch Log Groups for each container
resource "aws_cloudwatch_log_group" "container_logs" {
  for_each = toset([
    "pdf-extract",
    "pdf-convert",
    "pdf-process",
    "excel-analyze",
    "excel-generate",
    "excel-execute"
  ])
  
  name              = "/aws/ecs/${local.name_prefix}-${each.value}"
  retention_in_days = 30
}

# Data sources
data "aws_region" "current" {}