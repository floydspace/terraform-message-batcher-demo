output "x-api-key" {
  value     = module.appsync.appsync_api_key_key.default
  sensitive = true
}

output "api_url" {
  value = module.appsync.appsync_graphql_api_uris.GRAPHQL
}

output "ws_url" {
  value = module.appsync.appsync_graphql_api_uris.REALTIME
}
