resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

#-------------------------
# S3 simple bucket
#-------------------------
resource "aws_s3_bucket" "s3_static_bucket" {
  bucket = "${var.project}-${var.environment}-static-bucket-${random_string.s3_unique_key.result}"
}

resource "aws_s3_bucket_versioning" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_static_bucket" {
  bucket                  = aws_s3_bucket.s3_static_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "s3_static_bucket" {
#   bucket = aws_s3_bucket.s3_static_bucket.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"  // encrypt using KMS
#     }
#     bucket_key_enabled = true  // for cutting cost
#   }
# }

resource "aws_s3_bucket_lifecycle_configuration" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id

  rule {
    id     = "receipt-image-lifecycle"
    status = "Enabled"

    # Object: receipts/*
    filter {
      prefix = "users/"
    }
    expiration {
      days = 7 // image-file itself is not needed
    }
  }
}

resource "aws_s3_bucket_notification" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id

  # JPG
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_textract.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "users/"
    filter_suffix       = ".jpg"
  }

  # JPEG
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_textract.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "users/"
    filter_suffix       = ".jpeg"
  }

  # PNG
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_textract.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "users/"
    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}