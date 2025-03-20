locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sfn_state_machine" "document_processing" {
  name     = "${local.name_prefix}-document-processing"
  role_arn = var.sfn_role_arn

  definition = jsonencode({
    Comment = "Document Processing Pipeline for PDF and Excel files"
    StartAt = "CheckFileType"
    States = {
      "CheckFileType" = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.fileType"
            StringEquals = "PDF"
            Next = "ProcessPDF"
          },
          {
            Variable = "$.fileType"
            StringEquals = "EXCEL"
            Next = "ProcessExcel"
          },
          {
            Variable = "$.fileType"
            StringEquals = "BOTH"
            Next = "Parallel"
          }
        ]
        Default = "Failed"
      },
      
      "Parallel" = {
        Type = "Parallel"
        Branches = [
          {
            StartAt = "ProcessPDF"
            States = {
              "ProcessPDF" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.pdf_extract_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "pdf-extract"
                        Environment = [
                          {
                            Name = "S3_KEY"
                            Value = "$.pdfKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                Next = "ConvertPDFPages"
              },
              "ConvertPDFPages" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.pdf_convert_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "pdf-convert"
                        Environment = [
                          {
                            Name = "PDF_PAGES_KEY"
                            Value = "$.pdfPagesKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                Next = "ProcessPDFWithBedrock"
              },
              "ProcessPDFWithBedrock" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.pdf_process_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "pdf-process"
                        Environment = [
                          {
                            Name = "IMAGE_KEY"
                            Value = "$.imageKey"
                          },
                          {
                            Name = "DATA_MODEL_KEY"
                            Value = "$.dataModelKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          },
                          {
                            Name = "DATA_MODEL_BUCKET"
                            Value = "$.dataModelBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                End = true
              }
            }
          },
          {
            StartAt = "ProcessExcel"
            States = {
              "ProcessExcel" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.excel_analyze_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "excel-analyze"
                        Environment = [
                          {
                            Name = "EXCEL_KEY"
                            Value = "$.excelKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                Next = "GenerateExcelScript"
              },
              "GenerateExcelScript" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.excel_generate_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "excel-generate"
                        Environment = [
                          {
                            Name = "EXCEL_METADATA_KEY"
                            Value = "$.excelMetadataKey"
                          },
                          {
                            Name = "DATA_MODEL_KEY"
                            Value = "$.dataModelKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          },
                          {
                            Name = "DATA_MODEL_BUCKET"
                            Value = "$.dataModelBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                Next = "ExecuteExcelScript"
              },
              "ExecuteExcelScript" = {
                Type = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType = "FARGATE"
                  Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
                  TaskDefinition = var.excel_execute_task_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets = data.aws_subnets.private.ids
                      SecurityGroups = [aws_security_group.ecs_tasks.id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "excel-execute"
                        Environment = [
                          {
                            Name = "EXCEL_KEY"
                            Value = "$.excelKey"
                          },
                          {
                            Name = "SCRIPT_KEY"
                            Value = "$.scriptKey"
                          },
                          {
                            Name = "INPUT_BUCKET"
                            Value = "$.inputBucket"
                          },
                          {
                            Name = "OUTPUT_BUCKET"
                            Value = "$.outputBucket"
                          }
                        ]
                      }
                    ]
                  }
                }
                End = true
              }
            }
          }
        ]
        Next = "Success"
      },
      
      "ProcessPDF" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.pdf_extract_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "pdf-extract"
                Environment = [
                  {
                    Name = "S3_KEY"
                    Value = "$.pdfKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "ConvertPDFPages"
      },
      "ConvertPDFPages" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.pdf_convert_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "pdf-convert"
                Environment = [
                  {
                    Name = "PDF_PAGES_KEY"
                    Value = "$.pdfPagesKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "ProcessPDFWithBedrock"
      },
      "ProcessPDFWithBedrock" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.pdf_process_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "pdf-process"
                Environment = [
                  {
                    Name = "IMAGE_KEY"
                    Value = "$.imageKey"
                  },
                  {
                    Name = "DATA_MODEL_KEY"
                    Value = "$.dataModelKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  },
                  {
                    Name = "DATA_MODEL_BUCKET"
                    Value = "$.dataModelBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "Success"
      },
      
      "ProcessExcel" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.excel_analyze_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "excel-analyze"
                Environment = [
                  {
                    Name = "EXCEL_KEY"
                    Value = "$.excelKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "GenerateExcelScript"
      },
      "GenerateExcelScript" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.excel_generate_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "excel-generate"
                Environment = [
                  {
                    Name = "EXCEL_METADATA_KEY"
                    Value = "$.excelMetadataKey"
                  },
                  {
                    Name = "DATA_MODEL_KEY"
                    Value = "$.dataModelKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  },
                  {
                    Name = "DATA_MODEL_BUCKET"
                    Value = "$.dataModelBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "ExecuteExcelScript"
      },
      "ExecuteExcelScript" = {
        Type = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType = "FARGATE"
          Cluster = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.name_prefix}-cluster"
          TaskDefinition = var.excel_execute_task_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets = data.aws_subnets.private.ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "excel-execute"
                Environment = [
                  {
                    Name = "EXCEL_KEY"
                    Value = "$.excelKey"
                  },
                  {
                    Name = "SCRIPT_KEY"
                    Value = "$.scriptKey"
                  },
                  {
                    Name = "INPUT_BUCKET"
                    Value = "$.inputBucket"
                  },
                  {
                    Name = "OUTPUT_BUCKET"
                    Value = "$.outputBucket"
                  }
                ]
              }
            ]
          }
        }
        Next = "Success"
      },
      
      "Success" = {
        Type = "Succeed"
      },
      
      "Failed" = {
        Type = "Fail",
        Error = "FileTypeNotSupported",
        Cause = "The file type provided is not supported or was not specified"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_function_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch log group for Step Functions
resource "aws_cloudwatch_log_group" "step_function_logs" {
  name              = "/aws/stepfunctions/${local.name_prefix}-document-processing"
  retention_in_days = 30
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "selected" {
  id = var.vpc_id
}
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "subnet-id"
    values = var.private_subnet_ids
  }
}