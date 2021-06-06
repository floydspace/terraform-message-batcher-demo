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
