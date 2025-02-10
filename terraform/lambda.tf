# Lambda Layer for Pillow library
data "archive_file" "pillow_layer_package" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_imageresize/lambda_layer"
  output_path = "${path.module}/files/pillow_layer_package.zip"
}

resource "aws_lambda_layer_version" "pillow_layer" {
  layer_name          = "PillowLayer"
  filename            = data.archive_file.pillow_layer_package.output_path
  source_code_hash    = data.archive_file.pillow_layer_package.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

# Archive files for Lambda functions
data "archive_file" "pngextract" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_pngextract/target"
  output_path = "${path.module}/deploy_code/multipagepdfa2i_pngextract.zip"
}

data "archive_file" "analyzepdf" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_analyzepdf"
  output_path = "${path.module}/files/analyzepdf.zip"
}

data "archive_file" "humancomplete" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_humancomplete"
  output_path = "${path.module}/files/humancomplete.zip"
}

data "archive_file" "wrapup" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_wrapup"
  output_path = "${path.module}/files/wrapup.zip"
}

data "archive_file" "inserttodynamodb" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_inserttodynamodb"
  output_path = "${path.module}/files/inserttodynamodb.zip"
}

data "archive_file" "imageresize" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_imageresize/lambda"
  output_path = "${path.module}/files/imageresize.zip"
}

data "archive_file" "kickoff" {
  type        = "zip"
  source_dir  = "${path.module}/deploy_code/multipagepdfa2i_kickoff"
  output_path = "${path.module}/files/kickoff.zip"
}

# Lambda Functions
resource "aws_lambda_function" "pngextract" {
  filename         = "./deploy_code/multipagepdfa2i_pngextract/multipagepdfa2i_pngextract.jar"
  function_name    = "multipagepdfa2i_pngextract"
  role            = aws_iam_role.lambda_pngextract.arn
  handler         = "Lambda::handleRequest"
  runtime         = "java21"
  timeout         = 900
  memory_size     = 3000

  environment {
    variables = {
    }
  }
}

resource "aws_lambda_function" "analyzepdf" {
  filename         = data.archive_file.analyzepdf.output_path
  function_name    = "multipagepdfa2i_analyzepdf"
  role            = aws_iam_role.lambda_analyzepdf.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.analyzepdf.output_base64sha256
  runtime         = "python3.12"
  timeout         = 180
  memory_size     = 3000

  environment {
    variables = {
      sqs_url            = aws_sqs_queue.bedrock_queue.url
      human_workflow_arn = var.sagemaker_workflow_augmented_ai_arn
      ddb_tablename      = aws_dynamodb_table.callback.name
    }
  }
}

resource "aws_lambda_function" "humancomplete" {
  filename         = data.archive_file.humancomplete.output_path
  function_name    = "multipagepdfa2i_humancomplete"
  role            = aws_iam_role.lambda_humancomplete.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.humancomplete.output_base64sha256
  runtime         = "python3.12"
  timeout         = 900
  memory_size     = 3000

  environment {
    variables = {
      ddb_tablename = aws_dynamodb_table.callback.name
    }
  }
}

resource "aws_lambda_function" "wrapup" {
  filename         = data.archive_file.wrapup.output_path
  function_name    = "multipagepdfa2i_wrapup"
  role            = aws_iam_role.lambda_wrapup.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.wrapup.output_base64sha256
  runtime         = "python3.12"
  timeout         = 900
  memory_size     = 3000
}

resource "aws_lambda_function" "inserttodynamodb" {
  filename         = data.archive_file.inserttodynamodb.output_path
  function_name    = "multipagepdfa2i_inserttodynamodb"
  role            = aws_iam_role.lambda_inserttodynamodb.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.inserttodynamodb.output_base64sha256
  runtime         = "python3.12"
  timeout         = 900
  memory_size     = 3000

  environment {
    variables = {
      ddb_tablename = aws_dynamodb_table.vital_birth_data.name
    }
  }
}

resource "aws_lambda_function" "imageresize" {
  filename         = data.archive_file.imageresize.output_path
  function_name    = "multipagepdfa2i_imageresize"
  role             = aws_iam_role.lambda_imageresize.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  memory_size      = 512
  timeout          = 30
  layers = [aws_lambda_layer_version.pillow_layer.arn]
  package_type = "Zip"

  environment {
    variables = {
    }
  }
}


resource "aws_lambda_function" "kickoff" {
  filename         = data.archive_file.kickoff.output_path
  function_name    = "multipagepdfa2i_kickoff"
  role            = aws_iam_role.lambda_kickoff.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.kickoff.output_base64sha256
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 3000

  environment {
    variables = {
      sqs_url = aws_sqs_queue.sf_queue.url
      state_machine_arn = aws_sfn_state_machine.multipagepdfa2i.arn
    }
  }
}

# Lambda Event Source Mappings
resource "aws_lambda_event_source_mapping" "kickoff_sqs_trigger" {
  event_source_arn = aws_sqs_queue.sf_queue.arn
  function_name    = aws_lambda_function.kickoff.arn
  batch_size       = 1
}

resource "aws_lambda_event_source_mapping" "analyzepdf_sqs_trigger" {
  event_source_arn = aws_sqs_queue.bedrock_queue.arn
  function_name    = aws_lambda_function.analyzepdf.arn
  batch_size       = 1
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each          = toset([
    "kickoff", "pngextract", "analyzepdf", "humancomplete",
    "wrapup", "imageresize", "inserttodynamodb"
  ])
  name              = "/aws/lambda/multipagepdfa2i_${each.value}"
  retention_in_days = 7
}