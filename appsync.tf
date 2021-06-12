module "appsync" {
  source = "terraform-aws-modules/appsync/aws"

  name   = "${local.service_name}-graphql-api-${var.stage}"
  schema = file("graphql/schema.graphql")

  logging_enabled     = true
  log_field_log_level = "ALL"

  api_keys = {
    default = null
  }

  datasources = {
    dynamodb_datasource = {
      type       = "AMAZON_DYNAMODB"
      table_name = aws_dynamodb_table.default.name
      region     = var.region
    }
    none_datasource = {
      type = "NONE"
    }
  }

  resolvers = {
    "Query.batches" = {
      data_source = "dynamodb_datasource"
      request_template = jsonencode({
        version   = "2017-02-28"
        operation = "Scan"
      })
      response_template = "$utils.toJson($context.result.items)"
    }

    "Mutation.batchCreate" = {
      data_source       = "dynamodb_datasource"
      request_template  = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "UpdateItem",
    "key" : {
        "criteria" : $util.dynamodb.toDynamoDBJson($ctx.args.criteria)
    },
    "update" : {
        "expression" : "SET #messages = list_append(if_not_exists(#messages, :empty_list), :message)",
        "expressionNames" : {
            "#messages" : "messages"
        },
        "expressionValues" : {
            ":message" : $util.dynamodb.toDynamoDBJson([$ctx.args.message]),
            ":empty_list": { "L" : [] }
        }
    }
}
EOF
      response_template = "$utils.toJson($context.result)"
    }

    "Mutation.batchRelease" = {
      data_source       = "none_datasource"
      request_template  = <<EOF
{
  "version": "2017-02-28",
  "payload": $utils.toJson($context.arguments)
}
EOF
      response_template = "$utils.toJson($context.result)"
    }
  }
}
