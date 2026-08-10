data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "imports_bucket" {
  bucket = var.s3_imports

  tags = {
    Name        = var.s3_imports
    Environment = var.stage
  }
}

resource "aws_s3_bucket_public_access_block" "imports_bucket_pab" {
  bucket = aws_s3_bucket.imports_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "imports_bucket_encryption" {
  bucket = aws_s3_bucket.imports_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#ETL 
resource "aws_s3_bucket" "buckets" {
  for_each = var.s3_buckets

  bucket = each.value

  tags = {
    Name        = each.value
    Environment = var.stage
  }
}

resource "aws_s3_bucket_public_access_block" "buckets_pab" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets_encryption" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "images" {
  bucket = aws_s3_bucket.buckets["s3_images"].id

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.buckets["s3_images"].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.aws_cloudfront_images_arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "export_sources_versioning" {
  bucket = aws_s3_bucket.buckets["s3_export_sources"].id
  
  versioning_configuration {
    status = "Enabled"
  }
}