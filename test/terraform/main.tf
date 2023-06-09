#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "test" {
  name = "test"
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "test2" {
  name = "test2"
}

resource "aws_cloudwatch_log_stream" "foo" {
  name           = "test"
  log_group_name = aws_cloudwatch_log_group.test.name
}

resource "aws_cloudwatch_log_stream" "foo2" {
  name           = "test2"
  log_group_name = aws_cloudwatch_log_group.test2.name
}

module "test" {
  source = "../../"

  log_forwarder_lambda_function_name     = "test-fn-name"
  log_forwarder_lambda_region            = "eu-west-1"
  log_forwarder_lambda_concurrency_limit = 2
  log_forwarder_lambda_ttl               = 12
  log_forwarder_lambda_memory_size       = 188
  log_forwarder_lambda_log_level         = "trace"
  lambda_enable_dashboard                = true

  default_tags = {
    "tag-test-key" = "tag-test-value"
  }

  cloudwatch_log_group_subscriptions = [
    {
      arn    = aws_cloudwatch_log_group.test.arn
      region = "eu-west-1"
      key    = aws_cloudwatch_log_group.test.name
    },
    {
      arn    = aws_cloudwatch_log_group.test2.arn
      region = "eu-west-1"
      key    = aws_cloudwatch_log_group.test2.name
    }
  ]
  elastic_search_index       = "test_1"
  elastic_search_password    = "test"
  elastic_search_url         = "http://test-elk-1:9200/_bulk"
  elastic_search_username    = "test"
  elastic_request_timeout_ms = 4242
  elastic_search_retry_count = 6
}

output "lambda_function" {
  value       = module.test.lambda_function
  description = "lambda_function"
}

output "cloudwatch_subscriptions" {
  value       = module.test.cloudwatch_subscriptions
  description = "cloudwatch_subscriptions"
}

output "lambda_execution_role" {
  value       = module.test.lambda_execution_role
  description = "lambda_execution_role"
}

output "lambda_function_role" {
  value       = module.test.lambda_function_role
  description = "lambda_function_role"
}

output "log_subscription_permission" {
  value       = module.test.log_subscription_permission
  description = "log_subscription_permission"
}

output "cloudwatch_dashboard" {
  value       = module.test.cloudwatch_dashboard
  description = "cloudwatch_dashboard"
}
