output "web_url" {
  value = "https://${aws_cloudfront_distribution.default.domain_name}"
}
