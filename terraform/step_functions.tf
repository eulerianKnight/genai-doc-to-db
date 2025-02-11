resource "aws_sfn_state_machine" "multipagepdfa2i" {
  name     = "multipagepdfa2i_stepfunction"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    StartAt = "PDF or Image?"
    States = {
      "PDF or Image?" = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.extension"
            StringEquals = "pdf"
            Next = "PDF. Convert to PNGs"
          },
          {
            Variable = "$.extension"
            StringEquals = "png"
            Next = "Image. Passing."
          },
          {
            Variable = "$.extension"
            StringEquals = "jpg"
            Next = "Image. Passing."
          }
        ]
        Default = "PDF. Convert to PNGs"
      }

      "PDF. Convert to PNGs" = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.pngextract.arn
          Payload = {
            "bucket.$": "$.bucket"
            "key.$": "$.key"
            "id.$": "$.id"
          }
        }
        ResultPath = "$.image_keys"
        Next = "Image Resize"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ]
      }

      "Image. Passing." = {
        Type = "Pass"
        Result = ["single_image"]
        ResultPath = "$.image_keys"
        Next = "Image Resize"
      }

      "Image Resize" = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.imageresize.arn
          Payload = {
            "bucket.$": "$.bucket"
            "key.$": "$.key"
            "id.$": "$.id"
            "image_keys.$": "$.image_keys"
          }
        }
        ResultPath = "$.Input"
        Next = "Process_Map"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ]
      }

      "Process_Map" = {
        Type = "Map"
        InputPath = "$.Input"
        ItemsPath = "$.pages"
        MaxConcurrency = 1
        Iterator = {
          StartAt = "Analyze PDF"
          States = {
            "Analyze PDF" = {
              Type = "Task"
              Resource = "arn:aws:states:::sqs:sendMessage.waitForTaskToken"
              Parameters = {
                QueueUrl = aws_sqs_queue.bedrock_queue.url
                MessageBody = {
                  "taskToken.$": "$$.Task.Token"
                  "id.$": "$.id"
                  "bucket.$": "$.bucket"
                  "key.$": "$.key"
                  "wip_key.$": "$.wip_key"
                  "type": "analyze_pdf"  # Add a type identifier
                }
                # Add MessageAttributes if needed
                MessageAttributes = {
                  "TaskType": {
                    DataType = "String"
                    StringValue = "analyze_pdf"
                  }
                }
              }
              End = true
              TimeoutSeconds = 3600  # Add timeout to prevent infinite waiting
              Retry = [
                {
                  ErrorEquals = ["States.Timeout", "States.TaskFailed"],
                  IntervalSeconds = 2,
                  MaxAttempts = 3,
                  BackoffRate = 2.0
                }
              ]
            }
          }
        }
        Next = "Wrapup and Clean"
      }

      "Wrapup and Clean" = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.wrapup.arn
          Payload = {
            "bucket.$": "$.bucket"
            "key.$": "$.key"
            "id.$": "$.id"
          }
        }
        ResultSelector = {
          "s3path.$": "$.Payload"
        }
        Next = "Insert to dynamodb"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ]
      }

      "Insert to dynamodb" = {
        Type = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.inserttodynamodb.arn
          Payload = {
            "bucket.$": "$.bucket"
            "key.$": "$.key"
            "id.$": "$.id"
            "s3path.$": "$.s3path"
          }
        }
        ResultPath = "$.Input"
        End = true
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"],
            IntervalSeconds = 2,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ]
      }
    }
  })
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.stepfunctions.arn}:*"
    level                 = "ALL"
    include_execution_data = true
  }
}