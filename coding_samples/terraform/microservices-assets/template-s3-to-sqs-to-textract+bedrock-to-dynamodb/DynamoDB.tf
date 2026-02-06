#-------------------------
# DynamoDB
#-------------------------
resource "aws_dynamodb_table" "receipts" {
  name         = "Receipts"
  billing_mode = "PAY_PER_REQUEST" // on demand
  hash_key     = "user_id"
  range_key    = "receipt_id"

  attribute {
    name = "user_id"
    type = "S" // String
  }

  attribute {
    name = "receipt_id"
    type = "S" // String
  }

  attribute {
    name = "date"
    type = "S" // String(ISO: 2026-02-04)
  }

  # Global Secondary Index for searching for date
  # ex-query: user_id = "Nezness" AND date BETWEEN "2026-01-01" AND "2026-01-31"

  global_secondary_index {
    name            = "user-date-index"
    hash_key        = "user_id"
    range_key       = "date"
    projection_type = "ALL" // no need more query
  }

  point_in_time_recovery {
    enabled = false // If it's time to publish this app, change this to "true"
  }

  server_side_encryption {
    enabled = true # AWS-KMS
    # kms_key_arn = aws_kms_key.~.arn // If you wanna use own key
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  tags = {
    Name        = "Receipts"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# UserBudget management table
resource "aws_dynamodb_table" "user_budgets" {
  name         = "UserBudgets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "month" // "YYYY-MM"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "month"
    type = "S" // "YYYY-MM"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = false // Change this to true when publishing
  }

  tags = {
    Name        = "UserBudgets"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# UserBudget management table
resource "aws_dynamodb_table" "users" {
  name         = "Users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "UserBudgets"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "dynamodb_receipts_table_name" {
  value       = aws_dynamodb_table.receipts.name
  description = "Name of Receipts table"
}

output "dynamodb_receipts_table_arn" {
  value       = aws_dynamodb_table.receipts.arn
  description = "Name of Receipts table"
}

output "dynamodb_user_budgets_table_name" {
  value       = aws_dynamodb_table.user_budgets.name
  description = "Name of UserBudgets table"
}

output "dynamodb_user_budgets_table_arn" {
  value       = aws_dynamodb_table.user_budgets.arn
  description = "ARN of UserBudgets table"
}