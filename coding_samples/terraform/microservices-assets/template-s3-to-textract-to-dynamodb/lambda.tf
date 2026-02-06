#-------------------------
# AWS Lambda function // Python 3.12
#-------------------------
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
  timeout          = 30
}