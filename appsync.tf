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
  }
}
