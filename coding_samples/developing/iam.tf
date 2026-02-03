#-------------------------
# IAM role
#-------------------------
resource "aws_iam_role" "Lambda_role_s3_to_textract" {
  name               = "${var.project}-${var.environment}-lambda-s3-to-textract"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_s3_to_textract.json
}

#-------------------------
# Assume role policy // Who can use this
#-------------------------
data "aws_iam_policy_document" "lambda_assume_role_s3_to_textract" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#-------------------------
# Permissions Policy // What can this do
#-------------------------
data "aws_iam_policy_document" "lambda_permissions_s3_to_textract" {
  statement {
    effect = "Allow"
    actions = [
      "textract:AnalyzeExpense",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.s3_static_bucket.arn,
      "${aws_s3_bucket.s3_static_bucket.arn}/*"
    ]
  }
}

#-------------------------
# Other
#-------------------------
resource "aws_iam_policy" "lambda_policy_s3_to_textract" {
  name   = "${var.project}-${var.environment}-lambda-policy-s3-to-textract"
  policy = data.aws_iam_policy_document.lambda_permissions_s3_to_textract.json
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-s3-to-textract" {
  role       = aws_iam_role.Lambda_role_s3_to_textract.name
  policy_arn = aws_iam_policy.lambda_policy_s3_to_textract.arn
}

resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_textract.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_static_bucket.arn
}