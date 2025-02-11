# Data sources for current region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Create a data source for Lambda ARNs
data "aws_lambda_function" "functions" {
  for_each = toset([
    "multipagepdfa2i_imageresize",
    "multipagepdfa2i_inserttodynamodb",
    "multipagepdfa2i_pngextract",
    "multipagepdfa2i_wrapup",
    "multipagepdfa2i_humancomplete",
    "multipagepdfa2i_analyzepdf",
    "multipagepdfa2i_kickoff"
  ])
  function_name = each.value
  depends_on    = [
    aws_lambda_function.imageresize,
    aws_lambda_function.inserttodynamodb,
    aws_lambda_function.pngextract,
    aws_lambda_function.wrapup,
    aws_lambda_function.humancomplete,
    aws_lambda_function.analyzepdf,
    aws_lambda_function.kickoff
  ]
}

# Lambda IAM Roles
resource "aws_iam_role" "lambda_kickoff" {
  name = "multipagepdfa2i_lam_role_kickoff"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_kickoff" {
  name = "multipagepdfa2i_lambda_kickoff_policy"
  role = aws_iam_role.lambda_kickoff.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.sf_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = "*"  # We'll tighten this after creation
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_kickoff:*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_pngextract" {
  name = "multipagepdfa2i_lam_role_pngextract"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_pngextract" {
  name = "multipagepdfa2i_lambda_pngextract_policy"
  role = aws_iam_role.lambda_pngextract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/aws/lambda/multipagepdfa2i_pngextract:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_pngextract:*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_analyzepdf" {
  name = "multipagepdfa2i_lam_role_analyzepdf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_analyzepdf" {
  name = "multipagepdfa2i_lambda_analyzepdf_policy"
  role = aws_iam_role.lambda_analyzepdf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sagemaker:StartHumanLoop"]
        Resource = "arn:aws:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:flow-definition/*"
      },
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.callback.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_analyzepdf:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.sf_queue.arn,
          aws_sqs_queue.bedrock_queue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["states:SendTaskSuccess"]
        Resource = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:multipagepdfa2i_stepfunction"
      },
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          aws_ssm_parameter.birthcertificate_key_values.arn,
          aws_ssm_parameter.birthcertificate_validation_required.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}

# Step Functions IAM Role
resource "aws_iam_role" "step_functions" {
  name = "multipagepdfa2i_stepfunctions_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# Separate CloudWatch Logs policy
resource "aws_iam_role_policy" "step_functions_cloudwatch" {
  name = "multipagepdfa2i_stepfunctions_cloudwatch_policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.stepfunctions.arn}:*"
      }
    ]
  })
}

# Main Step Functions policy for other permissions
resource "aws_iam_role_policy" "step_functions" {
  name = "multipagepdfa2i_stepfunctions_policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.bedrock_queue.arn
      },
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          "${aws_lambda_function.imageresize.arn}",
          "${aws_lambda_function.inserttodynamodb.arn}",
          "${aws_lambda_function.pngextract.arn}",
          "${aws_lambda_function.wrapup.arn}",
          "${aws_lambda_function.humancomplete.arn}",
          "${aws_lambda_function.analyzepdf.arn}",
          "${aws_lambda_function.kickoff.arn}"
        ]
      }
    ]
  })
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_imageresize" {
  name = "multipagepdfa2i_imageresize_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "lambda_imageresize" {
  name = "multipagepdfa2i_lambda_imageresize_policy"
  role = aws_iam_role.lambda_imageresize.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/aws/lambda/multipagepdfa2i_imageresize:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_imageresize:*"
      }
    ]
  })
}

# Human Complete Lambda Role
resource "aws_iam_role" "lambda_humancomplete" {
  name = "multipagepdfa2i_lam_role_humancomplete"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_humancomplete" {
  name = "multipagepdfa2i_lambda_humancomplete_policy"
  role = aws_iam_role.lambda_humancomplete.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = aws_dynamodb_table.callback.arn
      },
      {
        Effect = "Allow"
        Action = ["states:SendTaskSuccess"]
        Resource = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:multipagepdfa2i_stepfunction"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/aws/lambda/multipagepdfa2i_humancomplete:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_humancomplete:*"
      }
    ]
  })
}

# Wrapup Lambda Role
resource "aws_iam_role" "lambda_wrapup" {
  name = "multipagepdfa2i_lam_role_wrapup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_wrapup" {
  name = "multipagepdfa2i_lambda_wrapup_policy"
  role = aws_iam_role.lambda_wrapup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          aws_ssm_parameter.birthcertificate_key_values.arn,
          aws_ssm_parameter.birthcertificate_validation_required.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/aws/lambda/multipagepdfa2i_wrapup:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_wrapup:*"
      }
    ]
  })
}

# Insert to DynamoDB Lambda Role
resource "aws_iam_role" "lambda_inserttodynamodb" {
  name = "multipagepdfa2i_lam_role_inserttodynamodb"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_inserttodynamodb" {
  name = "multipagepdfa2i_lambda_inserttodynamodb_policy"
  role = aws_iam_role.lambda_inserttodynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.vital_birth_data.arn
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/aws/lambda/multipagepdfa2i_inserttodynamodb:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/multipagepdfa2i_inserttodynamodb:*"
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "kickoff" {
  function_name = aws_lambda_function.kickoff.function_name

  depends_on = [
    aws_sfn_state_machine.multipagepdfa2i,
    aws_lambda_function.kickoff
  ]
}

resource "aws_lambda_function_event_invoke_config" "update_env" {
  function_name = aws_lambda_function.kickoff.function_name

  depends_on = [
    aws_lambda_function_event_invoke_config.kickoff,
    aws_sfn_state_machine.multipagepdfa2i
  ]

  provisioner "local-exec" {
    command = "aws lambda update-function-configuration --function-name ${aws_lambda_function.kickoff.function_name} --environment Variables={sqs_url=${aws_sqs_queue.sf_queue.url},state_machine_arn=${aws_sfn_state_machine.multipagepdfa2i.arn}}"
  }
}