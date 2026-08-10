resource "aws_iam_role" "lambda_edge" {
  name = "${var.project}-lambda_edge_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [ 
                   "edgelambda.amazonaws.com",
                   "lambda.amazonaws.com"
                  ]                 
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "local_file" "lambda_index" {
  content = <<EOF
'use strict';

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  const authUser = "${data.aws_ssm_parameter.lambda_user.value}";
  const authPass = "${data.aws_ssm_parameter.lambda_pass.value}";
  const authString = 'Basic ' + Buffer.from(authUser + ':' + authPass).toString('base64');

  const path = request.uri;
  if (path.startsWith('/graphql') || path.startsWith('/s3')) {
    return callback(null, request);
  }

  if (!headers.authorization || headers.authorization[0].value !== authString) {
    const response = {
      status: '401',
      statusDescription: 'Unauthorized',
      headers: {
        'www-authenticate': [{
          key: 'WWW-Authenticate',
          value: 'Basic realm="Restricted Area"'
        }]
      }
    };
    return callback(null, response);
  }

  return callback(null, request);
};
EOF
  filename = "${path.module}/lambda-auth/index.js"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-auth"
  output_path = "${path.module}/lambda-auth.zip"

  depends_on = [local_file.lambda_index]
}

resource "aws_lambda_function" "basic_auth" {
  provider      = aws.us_east_1
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project}-basic-auth-protect-root"
  role          = aws_iam_role.lambda_edge.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  publish       = true
  memory_size   = 128
  timeout       = 3
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "random_password" "lambda_password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "lambda_basic_user" {
  name        = "/lambda-auth/username"
  type        = "SecureString"
  value       = var.auth_user
  description = "Lambda Basic Auth username"
}

resource "aws_ssm_parameter" "lambda_basic_pass" {
  name        = "/lambda-auth/password"
  type        = "SecureString"
  value       = random_password.lambda_password.result
  description = "Lambda Basic Auth password"
}

data "aws_ssm_parameter" "lambda_user" {
  name            = aws_ssm_parameter.lambda_basic_user.name
  with_decryption = true
}

data "aws_ssm_parameter" "lambda_pass" {
  name            = aws_ssm_parameter.lambda_basic_pass.name
  with_decryption = true
}
