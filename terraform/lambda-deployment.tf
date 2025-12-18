
# DATA archiving for Lambda Integration
data "archive_file" "lambda_zip" {
  count       = var.deploy_lambda ? 1 : 0
  type        = "zip"
  source_dir  = "../app"
  output_path = "${path.module}/lambda.zip"
}

# Role and Permission for Lambda Function
resource "aws_iam_role" "pretest_lambda_exec" {
  count = var.deploy_lambda ? 1 : 0
  name  = "pretest-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  count      = var.deploy_lambda ? 1 : 0
  role       = aws_iam_role.pretest_lambda_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function Creation

resource "aws_lambda_function" "pretest_lambda" {
  count         = var.deploy_lambda ? 1 : 0
  function_name = "pretest-lambda-function"
  filename      = data.archive_file.lambda_zip[0].output_path
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.pretest_lambda_exec[0].arn
  timeout       = 30
  memory_size   = 512
}



# API GATEWAY V2

resource "aws_apigatewayv2_api" "apigw_pt" {
  count         = var.deploy_lambda ? 1 : 0
  name          = "pretest_apigw_v2"
  protocol_type = "HTTP"
  target        = aws_lambda_function.pretest_lambda[0].invoke_arn
}

resource "aws_apigatewayv2_integration" "integration" {
  count            = var.deploy_lambda ? 1 : 0
  api_id           = aws_apigatewayv2_api.apigw_pt[0].id
  integration_type = "AWS_PROXY"
  description      = "Lambda Integration"
  # connection_type = "INTERNET"
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.pretest_lambda[0].invoke_arn
}

resource "aws_apigatewayv2_route" "route_root" {
  api_id    = aws_apigatewayv2_api.apigw_pt[0].id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.integration[0].id}"
}

# resource "aws_apigatewayv2_route" "route_pt" {
#   count     = var.deploy_lambda ? 1 : 0
#   api_id    = aws_apigatewayv2_api.apigw_pt[0].id
#   route_key = "ANY /ip"
#   target    = "integrations/${aws_apigatewayv2_integration.integration[0].id}"

# }
resource "aws_lambda_permission" "api_gatewayv2_permission" {
  count         = var.deploy_lambda ? 1 : 0
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowExecutionFromAPIGateway"
  function_name = aws_lambda_function.pretest_lambda[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw_pt[0].execution_arn}/*/*"
  depends_on    = [aws_apigatewayv2_api.apigw_pt]
}
