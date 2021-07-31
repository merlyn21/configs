# Setup next.js lambda function
resource "aws_lambda_function" "tf-lambda-ssr" {
  function_name = "tf-lambda-ssr"
  s3_bucket     = aws_s3_bucket.upload-lambda.bucket
  s3_key        = aws_s3_bucket_object.upload_lambda.key
  #  memory_size      = var.LAMBDA_DEFAULT_MEMORY
  runtime          = "nodejs12.x"
  role             = aws_iam_role.iam_for_tf-lambda-ssr.arn
  source_code_hash = data.archive_file.default_lambda.output_base64sha256
  handler          = "index.handler"
  publish          = true
  timeout          = 30

  depends_on = [aws_iam_role.iam_for_tf-lambda-ssr]
}

resource "aws_iam_role" "iam_for_tf-lambda-ssr" {
  name               = "iam_for_tf-lambda-ssr"
  assume_role_policy = file("./role/iam-role.json")

}

resource "aws_iam_policy" "tf-lambda-ssr_logging" {
  name        = "tf-lambda-ssr_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = file("./role/logging-policy.json")
}
