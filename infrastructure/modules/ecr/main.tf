locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create ECR repositories for each container
resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.repository_names)
  
  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = "IMMUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy for ECR repositories - keep only the latest 5 images
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the latest 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Repository policy to allow ECS to pull images
resource "aws_ecr_repository_policy" "repository_policy" {
  for_each = aws_ecr_repository.repositories
  
  repository = each.value.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}