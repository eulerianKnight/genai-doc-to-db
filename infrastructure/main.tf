terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment to use remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "document-processing/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Call the modules to create the infrastructure
module "storage" {
  source                   = "./modules/storage"
  project_name             = var.project_name
  environment              = var.environment
  input_bucket_name        = var.input_bucket_name
  output_bucket_name       = var.output_bucket_name
  data_model_bucket_name   = var.data_model_bucket_name
}

module "iam" {
  source                   = "./modules/iam"
  project_name             = var.project_name
  environment              = var.environment
  input_bucket_arn         = module.storage.input_bucket_arn
  output_bucket_arn        = module.storage.output_bucket_arn
  data_model_bucket_arn    = module.storage.data_model_bucket_arn
}

module "ecr" {
  source                   = "./modules/ecr"
  project_name             = var.project_name
  environment              = var.environment
  repository_names         = var.ecr_repository_names
}

module "lambda" {
  source                       = "./modules/lambda"
  project_name                 = var.project_name
  environment                  = var.environment
  input_bucket_arn             = module.storage.input_bucket_arn
  input_bucket_name            = module.storage.input_bucket_name
  output_bucket_arn            = module.storage.output_bucket_arn
  output_bucket_name           = module.storage.output_bucket_name
  data_model_bucket_name       = module.storage.data_model_bucket_name
  lambda_trigger_role_arn      = module.iam.lambda_trigger_role_arn
  lambda_processor_role_arn    = module.iam.lambda_processor_role_arn
  stepfunctions_state_machine_arn = module.stepfunctions.state_machine_arn
}

module "ecs" {
  source                  = "./modules/ecs"
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = var.vpc_id
  private_subnet_ids      = var.private_subnet_ids
  ecs_task_role_arn       = module.iam.ecs_task_role_arn
  ecs_execution_role_arn  = module.iam.ecs_execution_role_arn
  ecr_repository_urls     = module.ecr.repository_urls
  input_bucket_name       = module.storage.input_bucket_name
  output_bucket_name      = module.storage.output_bucket_name
  data_model_bucket_name  = module.storage.data_model_bucket_name
  bedrock_model_id        = var.bedrock_model_id
}

module "stepfunctions" {
  source                   = "./modules/stepfunctions"
  project_name             = var.project_name
  environment              = var.environment
  sfn_role_arn             = module.iam.sfn_role_arn
  pdf_extract_task_arn     = module.ecs.pdf_extract_task_arn
  pdf_convert_task_arn     = module.ecs.pdf_convert_task_arn
  pdf_process_task_arn     = module.ecs.pdf_process_task_arn
  excel_analyze_task_arn   = module.ecs.excel_analyze_task_arn
  excel_generate_task_arn  = module.ecs.excel_generate_task_arn
  excel_execute_task_arn   = module.ecs.excel_execute_task_arn
}

module "api_gateway" {
  source                   = "./modules/api_gateway"
  project_name             = var.project_name
  environment              = var.environment
  upload_lambda_arn        = module.lambda.upload_lambda_arn
  upload_lambda_invoke_arn = module.lambda.upload_lambda_invoke_arn
}

# Configure S3 event notifications to trigger the pipeline
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.storage.input_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda.trigger_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [
    module.lambda.trigger_lambda_permission
  ]
}