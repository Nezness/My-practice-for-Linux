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

  queue {
    queue_arn     = aws_sqs_queue.receipt_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "users/"
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.receipt_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "users/"
    filter_suffix = ".JPG"
  }

  queue {
    queue_arn     = aws_sqs_queue.receipt_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "users/"
    filter_suffix = ".png"
  }

  queue {
    queue_arn     = aws_sqs_queue.receipt_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "users/"
    filter_suffix = ".PNG"
  }
}

resource "aws_s3_bucket_cors_configuration" "receipt_bucket_cors" {
  bucket = aws_s3_bucket_notification.s3_static_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] # Put domain frontend has
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}