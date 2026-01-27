#-------------------------
# AWS WAF
#-------------------------
resource "aws_wafv2_web_acl" "waf" {
  name        = "${var.project}-${var.environment}-web-acl"
  scope       = "CLOUDFRONT" // Don't use "REGIONAL" because you set so, then will work for "ELB"(not CloudFront)
  description = "WAF for CloudFront"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS_Maneged_Rules_Common_Rule_Set"
    priority = 1

    override_action {
      none {} // Change this to "ex)count"
    }

    statement {
      managed_rule_group_statement {
        name        = "AWS_Maneged_Rules_Common_Rule_Set"
        vendor_name = "AWS"


        rule_action_override {
          action_to_use {
            count {} // Change this to a rule you hope
          }

          name = "r1"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["*"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWS_Maneged_Rules_Common_Metric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "main_web_acl_metric"
    sampled_requests_enabled   = false
  }
}