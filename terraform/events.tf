# List of file extensions to monitor
locals {
  file_extensions = [
    "pdf", "pDf", "pDF", "pdF", "PDF", "Pdf",
    "png", "pNg", "pNG", "pnG", "PNG", "Png",
    "jpg", "jPg", "jPG", "jpG", "JPG", "Jpg"
  ]
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.main.id

  dynamic "queue" {
    for_each = local.file_extensions
    content {
      queue_arn = aws_sqs_queue.sf_queue.arn
      events    = ["s3:ObjectCreated:*"]
      filter_prefix = "uploads/"
      filter_suffix = queue.value
    }
  }

  depends_on = [aws_sqs_queue_policy.allow_s3]
}

# SQS queue policy to allow S3 notifications
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.sf_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ToSendMessages"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.sf_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn": aws_s3_bucket.main.arn
          }
          StringEquals = {
            "aws:SourceAccount": data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Lambda permission for SQS to invoke kickoff function
resource "aws_lambda_permission" "allow_sqs_kickoff" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kickoff.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.sf_queue.arn
}

# Lambda permission for SQS to invoke analyzepdf function
resource "aws_lambda_permission" "allow_sqs_analyzepdf" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyzepdf.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.bedrock_queue.arn
}

# S3 bucket policy to enforce SSL/TLS
resource "aws_s3_bucket_policy" "require_ssl" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RequireSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}