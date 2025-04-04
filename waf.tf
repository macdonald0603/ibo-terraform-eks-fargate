# WAF Web ACL for ALB
resource "aws_wafv2_web_acl" "prod_waf" {
  name        = "prod-waf-acl"
  description = "WAFv2 Web ACL for prod"
  scope       = "REGIONAL"  # Use REGIONAL for ALBs

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "prod-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "SQLInjectionRule"
    priority = 1

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          all_query_arguments {}  # <-- Protects all query params instead of just query_string
        }

        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sql-injection-rule"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Environment = "Production"
    Owner       = "IBO John"
  }
}

# WAF Web ACL Association with ALB
resource "aws_wafv2_web_acl_association" "prod_waf_association" {
  resource_arn = aws_lb.public_alb.arn  # <-- Fix ALB reference
  web_acl_arn  = aws_wafv2_web_acl.prod_waf.arn
}