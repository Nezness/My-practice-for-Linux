#-------------------------
# IAM role
#-------------------------
resource "aws_iam_role" "Lambda_role_s3_to_textract" {
  name               = "${var.project}-${var.environment}-lambda-s3-to-textract"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_s3_to_textract.json
}

resource "aws_iam_role" "Lambda_role_to_s3" {
  name               = "${var.project}-${var.environment}-lambda-to-s3"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_to_s3.json
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

data "aws_iam_policy_document" "lambda_assume_role_to_s3" {
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
      "textract:DetectDocumentText",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "bedrock:InvokeModel",
      "aws-marketplace:ViewSubscriptions",
      "aws-marketplace:Subscribe",
      "aws-marketplace:Unsubscribe",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
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

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.receipts.arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_permissions_to_s3" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.s3_static_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
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

resource "aws_iam_policy" "lambda_policy_to_s3" {
  name   = "${var.project}-${var.environment}-lambda-policy-to-s3"
  policy = data.aws_iam_policy_document.lambda_permissions_to_s3.json
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attachment-to-s3" {
  role       = aws_iam_role.Lambda_role_to_s3.name
  policy_arn = aws_iam_policy.lambda_policy_to_s3.arn
}