#-------------------------
# AWS Lambda function // Python 3.12
#-------------------------
## For sending receipt to Textract
data "archive_file" "lambda_s3_to_textract_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_s3_to_textract.zip"
}

resource "aws_lambda_function" "s3_to_textract" {
  filename         = data.archive_file.lambda_s3_to_textract_zip.output_path // Path to zip
  function_name    = "${var.project}-${var.environment}-lambda-s3-to-textract"
  role             = aws_iam_role.Lambda_role_s3_to_textract.arn // Set IAMrole which can read s3 object
  handler          = "index.handler"                             // program-name.handler
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_s3_to_textract_zip.output_base64sha256
  timeout          = 60
}

## For Issuing presigned-url
data "archive_file" "lambda_to_s3_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_to_s3.zip"
}

resource "aws_lambda_function" "to_s3" {
  filename         = data.archive_file.lambda_to_s3_zip.output_path
  function_name    = "${var.project}-${var.environment}-lambda-to-s3"
  role             = aws_iam_role.Lambda_role_to_s3.arn
  handler          = "request.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_to_s3_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket_notification.s3_static_bucket.id
    }
  }
}