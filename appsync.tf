resource "aws_appsync_graphql_api" "default" {
  authentication_type = "API_KEY"
  name                = "${local.service_name}-graphql-api-${var.stage}"

  schema = <<EOF
type Mutation {
    batchCreate(criteria: String!): Batch
}

type Batch {
    criteria: String
    meta: String
}

type Query {
    batches: [Batch]
}

schema {
    query: Query
    mutation: Mutation
}
EOF

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.default.arn
    field_log_level          = "ALL"
  }
}

resource "aws_appsync_api_key" "default" {
  api_id = aws_appsync_graphql_api.default.id
}

resource "aws_appsync_resolver" "batches" {
  api_id      = aws_appsync_graphql_api.default.id
  type        = "Query"
  field       = "batches"
  data_source = aws_appsync_datasource.default.name

  request_template = jsonencode({
    version   = "2017-02-28"
    operation = "Scan"
  })

  response_template = "$utils.toJson($context.result.items)"
}

resource "aws_appsync_resolver" "Mutation_pipelineTest" {
  api_id      = aws_appsync_graphql_api.default.id
  type        = "Mutation"
  field       = "batchCreate"
  data_source = aws_appsync_datasource.default.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "criteria" : $util.dynamodb.toDynamoDBJson($ctx.args.criteria)
    },
    "attributeValues" : {
        "meta": { "S" : "Hi from AppSync!" },
    }
}
EOF

  response_template = "$utils.toJson($context.result)"
}

resource "aws_appsync_datasource" "default" {
  api_id           = aws_appsync_graphql_api.default.id
  name             = "${local.aws_default_tags.Space}_message_batcher_datasource_${var.stage}"
  service_role_arn = aws_iam_role.default.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.default.name
  }
}

resource "aws_iam_role" "default" {
  name = "${local.service_name}-datasource-${var.stage}-lambdaRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "${local.service_name}-datasource-${var.stage}-lambdaPolicy"
    policy = data.aws_iam_policy_document.default.json
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "default" {
  statement {
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.default.arn]
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
  role       = aws_iam_role.default.name
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/aws/appsync/apis/${aws_appsync_graphql_api.default.id}"
}
