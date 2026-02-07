#-------------------------
# SQS
#-------------------------
resource "aws_sqs_queue" "receipt_queue" {
  name                       = "receipt-processing-queue"
  message_retention_seconds  = 86400 // 1day
  visibility_timeout_seconds = 90    // given to waiting time for Bedrock
}

resource "aws_sqs_queue_policy" "receipt_queue_policy" {
  queue_url = aws_sqs_queue.receipt_queue.url
  policy    = data.aws_iam_policy_document.receipt_queue_policy_doc.json
}

data "aws_iam_policy_document" "receipt_queue_policy_doc" {
  statement {
    sid    = "AllowS3ToSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "sqs:SendMessage"
    ]
    resources = [aws_sqs_queue.receipt_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.s3_static_bucket.arn]
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.receipt_queue.arn
  function_name    = aws_lambda_function.s3_to_textract.arn
  batch_size       = 1
  enabled          = true
}