provider "aws" {
  region = "us-east-1"
}

# ── S3 ────────────────────────────────────────────────
resource "aws_s3_bucket" "bucket" {
  bucket = "image-storage-tf-12345"
}

# ── DynamoDB ──────────────────────────────────────────
resource "aws_dynamodb_table" "table" {
  name         = "Images_TF"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_name"

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "image_name"
    type = "S"
  }
}

# ── IAM Role ──────────────────────────────────────────
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role-tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Fix: Add DynamoDB Stream execution role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_stream" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

# ── Lambda Functions ──────────────────────────────────
resource "aws_lambda_function" "ingest_image" {
  function_name    = "IngestImageLambdaTF"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_ingest.lambda_handler"
  runtime          = "python3.9"
  filename         = "lambda_ingest.zip"
  source_code_hash = filebase64sha256("lambda_ingest.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.table.name
    }
  }
}

resource "aws_lambda_function" "process_image" {
  function_name    = "ProcessImageLambdaTF"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_process.lambda_handler"
  runtime          = "python3.9"
  filename         = "lambda_process.zip"
  source_code_hash = filebase64sha256("lambda_process.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.bucket
    }
  }
}

resource "aws_lambda_function" "get_image" {
  function_name    = "GetImageLambdaTF"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_get.lambda_handler"
  runtime          = "python3.9"
  filename         = "lambda_get.zip"
  source_code_hash = filebase64sha256("lambda_get.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.bucket
    }
  }
}

# ── DynamoDB Stream Trigger ───────────────────────────
resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  event_source_arn  = aws_dynamodb_table.table.stream_arn
  function_name     = aws_lambda_function.process_image.arn
  starting_position = "LATEST"
}

# ── API Gateway ───────────────────────────────────────
resource "aws_api_gateway_rest_api" "api" {
  name = "image-api-tf"
}

resource "aws_api_gateway_resource" "image_url" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "image_url"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.image_url.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ingest_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.image_url.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ingest_image.invoke_arn
}

resource "aws_lambda_permission" "apigw_ingest" {
  statement_id  = "AllowAPIGatewayIngestTF"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "get_image" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "get-image"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.get_image.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.get_image.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_image.invoke_arn
}

resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowAPIGatewayInvokeTF"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# ── Deployment ────────────────────────────────────────
resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.ingest_integration,
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "dev" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
}