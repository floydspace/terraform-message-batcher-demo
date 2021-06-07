locals {
  service_name = "${local.aws_default_tags.Space}-${local.aws_default_tags.Name}"
  aws_default_tags = {
    Space = "bgen"
    Name  = "message-batcher"
    Stage = var.stage
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_dynamodb_table" "default" {
  name             = "${local.service_name}-table-${var.stage}"
  hash_key         = "criteria"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  tags             = local.aws_default_tags

  attribute {
    name = "criteria"
    type = "S"
  }
}

resource "aws_sqs_queue" "default_queue" {
  name = "${local.service_name}-queue-${var.stage}"
  tags = local.aws_default_tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 2
  })
}

resource "aws_sqs_queue" "deadletter_queue" {
  name = "${local.service_name}-dlq-${var.stage}"
  tags = local.aws_default_tags
}

module "queue_message_lambda" {
  source = "./modules/aws_lambda"

  function_name    = "${local.service_name}-queue-message-${var.stage}"
  handler          = "app.handler"
  tags             = local.aws_default_tags
  event_source_arn = aws_sqs_queue.default_queue.arn

  source_path = "${path.cwd}/lambdas/queue_message"

  environment_variables = {
    TABLE_NAME = aws_dynamodb_table.default.id
  }

  policy_statements = [
    {
      actions   = ["dynamodb:DeleteItem"]
      resources = [aws_dynamodb_table.default.arn]
    },
    {
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = ["*"]
    },
  ]
}

module "dynamodb_stream_lambda" {
  source = "./modules/aws_lambda"

  function_name    = "${local.service_name}-dynamodb-stream-${var.stage}"
  handler          = "app.handler"
  tags             = local.aws_default_tags
  event_source_arn = aws_dynamodb_table.default.stream_arn

  source_path = "${path.cwd}/lambdas/dynamodb_stream"

  environment_variables = {
    QUEUE_ARN = aws_sqs_queue.default_queue.arn
  }

  policy_statements = [
    {
      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.default_queue.arn]
    },
    {
      actions   = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:ListStreams"]
      resources = ["*"]
    },
    {
      actions   = ["sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ListDeadLetterSourceQueues", "sqs:ListQueues"]
      resources = ["*"]
    },
  ]
}
