# AWS Budget to monitor monthly spending for EC2
resource "aws_budgets_budget" "ibo_prod_app_budget" {
  name              = "AppBudget"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 100.0
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    # List of subscribers for the notification
    subscriber_email_addresses = ["macdonald0603@msn.com"]
  }

  tags = {
    Name = "ibo_prod_app_budget"
  }
}


