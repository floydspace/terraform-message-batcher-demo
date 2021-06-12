resource "aws_s3_bucket" "default" {
  bucket = var.name
  acl    = "private"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadForGetBucketObjects",
        Action    = ["s3:GetObject"],
        Effect    = "Allow",
        Resource  = "arn:aws:s3:::${var.name}/*",
        Principal = "*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "default" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"

  origin {
    domain_name = aws_s3_bucket.default.bucket_regional_domain_name
    origin_id   = "website_bucket_origin"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website_bucket_origin"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = var.folder
}

resource "aws_s3_bucket_object" "default" {
  for_each = module.template_files.files

  bucket       = aws_s3_bucket.default.id
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content
  etag         = each.value.digests.md5
}
