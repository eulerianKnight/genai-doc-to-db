locals {
  input_bucket_name      = var.input_bucket_name != null ? var.input_bucket_name : "${var.project_name}-input-${var.environment}-${random_string.bucket_suffix.result}"
  output_bucket_name     = var.output_bucket_name != null ? var.output_bucket_name : "${var.project_name}-output-${var.environment}-${random_string.bucket_suffix.result}"
  data_model_bucket_name = var.data_model_bucket_name != null ? var.data_model_bucket_name : "${var.project_name}-data-model-${var.environment}-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = true
}

# S3 Bucket for input files (PDFs and Excel)
resource "aws_s3_bucket" "input_bucket" {
  bucket = local.input_bucket_name

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

resource "aws_s3_bucket_versioning" "input_bucket_versioning" {
  bucket = aws_s3_bucket.input_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "input_bucket_encryption" {
  bucket = aws_s3_bucket.input_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "input_bucket_lifecycle" {
  bucket = aws_s3_bucket.input_bucket.id

  rule {
    id     = "archive-old-files"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

# Create folder structure in input bucket
resource "aws_s3_object" "input_bucket_folders" {
  for_each = toset(["uploads/api/", "uploads/direct/", "uploads/console/"])
  
  bucket  = aws_s3_bucket.input_bucket.id
  key     = each.key
  content = ""
}

# S3 Bucket for output CSV files
resource "aws_s3_bucket" "output_bucket" {
  bucket = local.output_bucket_name

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

resource "aws_s3_bucket_versioning" "output_bucket_versioning" {
  bucket = aws_s3_bucket.output_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output_bucket_encryption" {
  bucket = aws_s3_bucket.output_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create folder structure in output bucket
resource "aws_s3_object" "output_bucket_folders" {
  for_each = toset(["pdf/", "excel/"])
  
  bucket  = aws_s3_bucket.output_bucket.id
  key     = each.key
  content = ""
}

# S3 Bucket for data models
resource "aws_s3_bucket" "data_model_bucket" {
  bucket = local.data_model_bucket_name

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

resource "aws_s3_bucket_versioning" "data_model_bucket_versioning" {
  bucket = aws_s3_bucket.data_model_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_model_bucket_encryption" {
  bucket = aws_s3_bucket.data_model_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS configuration for direct uploads
resource "aws_s3_bucket_cors_configuration" "input_bucket_cors" {
  bucket = aws_s3_bucket.input_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"] # Restrict to your application domains in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}