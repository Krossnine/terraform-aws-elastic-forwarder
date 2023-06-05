# For each log group, create a subscription filter to forward logs to the lambda function
resource "aws_cloudwatch_log_subscription_filter" "log_forwarder" {
  count = length(var.cloudwatch_log_group_subscriptions)

  name           = "${var.cloudwatch_log_group_subscriptions[count.index].key}-log-forwarder-subscription"
  log_group_name = var.cloudwatch_log_group_subscriptions[count.index].key

  filter_pattern  = var.cloudwatch_log_forward_filter_pattern
  destination_arn = aws_lambda_function.log_forwarder.arn

  depends_on = [
    aws_lambda_permission.allow_cloudwatch_to_invoke[*]
  ]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      aws_lambda_function.log_forwarder
    ]
  }
}
