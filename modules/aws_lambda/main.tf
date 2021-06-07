resource "aws_lambda_function" "default" {
  function_name    = var.function_name
  role             = aws_iam_role.default.arn
  filename         = data.archive_file.default.output_path
  source_code_hash = data.archive_file.default.output_base64sha256
  handler          = var.handler
  runtime          = "python3.8"
  tags             = var.tags

  dynamic "environment" {
    for_each = length(keys(var.environment_variables)) == 0 ? [] : [true]
    content {
      variables = var.environment_variables
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.default,
    aws_cloudwatch_log_group.default,
  ]
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = var.source_path
  output_path = "${path.cwd}/.deployment/${trimprefix(var.source_path, "${path.cwd}/")}.zip"
}

resource "aws_iam_role" "default" {
  name = "${var.function_name}-lambdaRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "${var.function_name}-lambdaPolicy"
    policy = data.aws_iam_policy_document.default.json
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/aws/lambda/${var.function_name}"
}

data "aws_iam_policy_document" "default" {
  dynamic "statement" {
    for_each = [for statement in var.policy_statements : statement]
    content {
      actions   = statement.value.actions
      resources = statement.value.resources
    }
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

resource "aws_lambda_event_source_mapping" "default" {
  event_source_arn  = var.event_source_arn
  function_name     = aws_lambda_function.default.arn
  starting_position = contains(split("/", var.event_source_arn), "stream") ? "LATEST" : null
  batch_size        = var.batch_size
  depends_on        = [aws_iam_role.default]
}
