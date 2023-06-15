#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "forwarder_log_group" {
  name              = "/aws/lambda/${var.log_forwarder_lambda_function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.default_tags
}
