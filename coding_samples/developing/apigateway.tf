#-------------------------
# API Gateway
#-------------------------
resource "aws_apigatewayv2_api" "receipt_api" {
  name          = "receipt-app-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.receipt_api.id
  name        = "$default"
  auto_deploy = true
}

# Connect API to Lambda
resource "aws_apigatewayv2_integration" "upload_integration" {
  api_id                 = aws_apigatewayv2_api.receipt_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.to_s3.invoke_arn
  payload_format_version = "2.0"
}

# Permission to Lambda
resource "aws_lambda_permission" "api_gw_invoke_upload" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.to_s3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.receipt_api.execution_arn}/*/*/upload-url"
}

# Output Endpoint-url
output "api_endpoint" {
  value = aws_apigatewayv2_api.receipt_api.api_endpoint
}

resource "aws_apigatewayv2_route" "upload_route" {
  api_id = aws_apigatewayv2_api.receipt_api.id
  route_key = "GET /upload-url"
  target = "integrations/${aws_apigatewayv2_integration.upload_integration.id}"
}