provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

resource "aws_s3_bucket" "yash_static_website" {
  bucket = "yash-s3-static-website"  # Ensure this is globally unique

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "yash_static_website_policy" {
  bucket = aws_s3_bucket.yash_static_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Service" = "cloudfront.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.yash_static_website.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.yash_cdn.id}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "yash_oai" {
  comment = "Origin Access Identity for S3"
}

data "aws_caller_identity" "current" {}

resource "aws_cloudfront_distribution" "yash_cdn" {
  origin {
    domain_name = aws_s3_bucket.yash_static_website.bucket_regional_domain_name
    origin_id   = "S3-yash-static-website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.yash_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-yash-static-website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.yash_cdn.domain_name
}

output "s3_website_url" {
  value = aws_s3_bucket.yash_static_website.website_endpoint
}
