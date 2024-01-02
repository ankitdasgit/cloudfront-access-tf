provider "aws" {
  region = "us-east-1" 
  access_key = "AKIAZYOGQOIBQJOLOG4O"
  secret_key = "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"

}

 
# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-s3-bucket7799"
  # acl    = "public-read"

  tags = {
    Name = "MyS3Bucket"
  }
}

resource "aws_s3_bucket_object" "my-s3_object1" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "image.png"
#  source = "C:/Users/DELL/OneDrive/Documents/terraform files/cloudfrontAccess/mage.png"
  source = "C:\\Users\\DELL\\OneDrive\\Documents\\terraform files\\cloudfrontAccess\\image.png"
}

resource "aws_s3_bucket_object" "my-s3_object2" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index page"
  source = "C:/Users/DELL/OneDrive/Documents/terraform files/cloudfrontAccess/index.html"
}

# Create a CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "My CloudFront OAI"
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront Distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.my_bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}




# Define the S3 bucket policy allowing CloudFront access
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Grant CloudFront Access"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.my_oai.iam_arn
        }
        Action   = [
          "s3:GetObject"
        ]
        Resource  = aws_s3_bucket.my_bucket.arn
      }
    ]
  })
}


output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.my_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}