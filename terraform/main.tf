# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = "multipagepdfa2i"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# DynamoDB Tables
resource "aws_dynamodb_table" "callback" {
  name         = "multia2ipdf_callback"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jobid"
  range_key    = "callback_token"
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "jobid"
    type = "S"
  }

  attribute {
    name = "callback_token"
    type = "S"
  }
}

resource "aws_dynamodb_table" "vital_birth_data" {
  name         = "Vital_Birth_Data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Name_of_applicant"
  range_key    = "Zip_code"
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "Name_of_applicant"
    type = "S"
  }

  attribute {
    name = "Zip_code"
    type = "S"
  }
}

# SQS Queues
resource "aws_sqs_queue" "sf_queue" {
  name                       = "multipagepdfa2i_sf_sqs"
  visibility_timeout_seconds = 300 # 5 minutes
}

resource "aws_sqs_queue" "bedrock_queue" {
  name                       = "multipagepdfa2i_bedrock_sqs"
  visibility_timeout_seconds = 180 # 3 minutes
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "stepfunctions" {
  name              = "/aws/stepfunctions/multipagepdfa2i_stepfunction_logs"
  retention_in_days = 7
}

# SSM Parameters
resource "aws_ssm_parameter" "birthcertificate_key_values" {
  name = "/business_rules/required_keys_values"
  type = "String"
  value = jsonencode([
    "Name_of_applicant", "Day_phone_number", "Address", "City", "State", "Zip_code",
    "Email_address", "Your_relationship_to_person_named_on_this_certificate",
    "For_what_purpose_are_you_requesting_this_certificate?", "Signature_of_applicant",
    "Name_on_birth_certificate_being_requested", "Date_of_birth", "Sex", "City_of_birth",
    "County_of_birth", "Name_of_mother_parent_prior_to_1st_marriage",
    "Name_of_father_parent_prior_to_1st_marriage",
    "Mother_parent_state_or_foreign_country_of_birth",
    "Father_parent_state_or_foreign_country_of_birth",
    "Were_parents_married_at_the_time_of_birth?", "Number_of_children_born_to_this_individual",
    "Required_Search_Fee", "Each_Additional_copy", "Total_fees_submitted"
  ])
}

resource "aws_ssm_parameter" "birthcertificate_validation_required" {
  name  = "/business_rules/validationrequied"
  type  = "String"
  value = "no"
}