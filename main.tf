locals {
  service_name = "${local.aws_default_tags.Space}-${local.aws_default_tags.Name}"
  aws_default_tags = {
    Space = "bgen"
    Name  = "message-batcher"
    Stage = var.stage
  }
}

provider "archive" {}

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

resource "aws_lambda_function" "queue_message" {
  function_name    = "${local.service_name}-queue-message-${var.stage}"
  role             = aws_iam_role.queue_message.arn
  filename         = data.archive_file.queue_message.output_path
  source_code_hash = data.archive_file.queue_message.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.8"
  tags             = local.aws_default_tags

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.default.id
    }
  }

  depends_on = [aws_iam_role_policy_attachment.queue_message, aws_cloudwatch_log_group.queue_message]
}

data "archive_file" "queue_message" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/queue_message"
  output_path = "${path.cwd}/.deployment/queue_message.zip"
}

resource "aws_iam_role" "queue_message" {
  name = "${local.service_name}-queue-message-${var.stage}-lambdaRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "${local.service_name}-queue-message-${var.stage}-lambdaPolicy"
    policy = data.aws_iam_policy_document.queue_message.json
  }
}

resource "aws_iam_role_policy_attachment" "queue_message" {
  role       = aws_iam_role.queue_message.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_cloudwatch_log_group" "queue_message" {
  name = "/aws/lambda/${local.service_name}-queue-message-${var.stage}"
}

data "aws_iam_policy_document" "queue_message" {
  statement {
    actions   = ["dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.default.arn]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_event_source_mapping" "queue_message" {
  event_source_arn = aws_sqs_queue.default_queue.arn
  function_name    = aws_lambda_function.queue_message.arn
  batch_size       = 1
  depends_on       = [aws_iam_role.queue_message]
}

resource "aws_lambda_function" "dynamodb_stream" {
  function_name    = "${local.service_name}-dynamodb-stream-${var.stage}"
  role             = aws_iam_role.dynamodb_stream.arn
  filename         = data.archive_file.dynamodb_stream.output_path
  source_code_hash = data.archive_file.dynamodb_stream.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.8"
  tags             = local.aws_default_tags

  environment {
    variables = {
      QUEUE_ARN = aws_sqs_queue.default_queue.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.dynamodb_stream,
    aws_iam_role_policy_attachment.sqs_access,
    aws_cloudwatch_log_group.dynamodb_stream,
  ]
}

data "archive_file" "dynamodb_stream" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/dynamodb_stream"
  output_path = "${path.cwd}/.deployment/dynamodb_stream.zip"
}

resource "aws_iam_role" "dynamodb_stream" {
  name = "${local.service_name}-dynamodb-stream-${var.stage}-lambdaRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "${local.service_name}-dynamodb-stream-${var.stage}-lambdaPolicy"
    policy = data.aws_iam_policy_document.dynamodb_stream.json
  }
}

resource "aws_iam_role_policy_attachment" "dynamodb_stream" {
  role       = aws_iam_role.dynamodb_stream.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  role       = aws_iam_role.dynamodb_stream.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
}

resource "aws_cloudwatch_log_group" "dynamodb_stream" {
  name = "/aws/lambda/${local.service_name}-dynamodb-stream-${var.stage}"
}

data "aws_iam_policy_document" "dynamodb_stream" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.default_queue.arn]
  }
}

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = aws_dynamodb_table.default.stream_arn
  function_name     = aws_lambda_function.dynamodb_stream.arn
  starting_position = "LATEST"
  batch_size        = 1
  depends_on        = [aws_iam_role.dynamodb_stream]
}
