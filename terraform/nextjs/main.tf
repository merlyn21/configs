
terraform {
  backend "s3" {
    bucket = "qi-hvt-test-tf-state"
    key            = "test/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "qi_hvt_test-terraform-state-locks"
    encrypt        = true
  }
}


module "s3_files" {
  source = "hashicorp/dir/template"

  #  base_dir = "${path.module}/../s3"
  base_dir   = "./.serverless_nextjs/assets"
  file_types = local.file_types
}

locals {

  cloudfront_s3_origin_id = "hvt-origin"
  file_types = {
    ".txt"   = "text/plain; charset=utf-8"
    ".html"  = "text/html; charset=utf-8"
    ".css"   = "text/css; charset=utf-8"
    ".js"    = "application/javascript"
    ".xml"   = "application/xml"
    ".json"  = "application/json"
    ".gif"   = "image/gif"
    ".jpeg"  = "image/jpeg"
    ".jpg"   = "image/jpeg"
    ".png"   = "image/png"
    ".svg"   = "image/svg+xml"
    ".webp"  = "image/webp"
    ".weba"  = "audio/webm"
    ".webm"  = "video/webm"
    ".pdf"   = "application/pdf"
    ".ico"   = "image/vnd.microsoft.icon"
    ".ttf"   = "font/ttf"
    ".otf"   = "font/otf"
    ".eot"   = "application/vnd.ms-fontobject"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
  }
}


provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}

# Pull in shared infrastructure

# S3 bucket static
resource "aws_s3_bucket" "bucket-static-946" {
  bucket = "hdc-srvl-9aurle"
  acl    = "private"
}

# S3 bucket upload
resource "aws_s3_bucket" "upload-lambda" {
  bucket = "upload-labmda-9aurle"
  acl    = "private"
}


# resource "aws_s3_bucket_object" "upload_lambda" {
#   #  for_each = fileset("s3/", "*")
#   bucket = aws_s3_bucket.upload-lambda.bucket
#   key    = "default.zip"
#   source = "lambda/default.zip"
#   etag   = filemd5("lambda/default.zip")
# }

resource "aws_s3_bucket_object" "upload_s3_files" {
  for_each = module.s3_files.files

  bucket       = aws_s3_bucket.bucket-static-946.bucket
  key          = each.key
  source       = each.value.source_path
  content_type = each.value.content_type
  etag         = filemd5("./.serverless_nextjs/assets/${each.key}")
}

data "archive_file" "default_lambda" {
  type = "zip"
  #  output_path = "${path.module}/../lambda/default.zip"
  #  source_dir  = "${path.module}/../.serverless_nextjs/default-lambda"
  output_path = "lambda/default.zip"
  source_dir  = ".serverless_nextjs/default-lambda"
}

resource "aws_s3_bucket_object" "upload_lambda" {
  #  for_each = fileset("s3/", "*")
  bucket = aws_s3_bucket.upload-lambda.bucket
  key    = "default.zip"
  source = data.archive_file.default_lambda.output_path
  etag   = filemd5(data.archive_file.default_lambda.output_path)
}

resource "aws_cloudfront_origin_access_identity" "bucket-static-946_access_identity" {
  comment = "Cloudfront access identity"
}
