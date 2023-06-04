resource "aws_cloudwatch_log_group" "my_first_log_group" {
  name              = var.name
  retention_in_days = 30
}

output "my_first_log_group_output" {
  value = {
    key    = aws_cloudwatch_log_group.my_first_log_group.name,
    arn    = aws_cloudwatch_log_group.my_first_log_group.arn,
    region = "us-east-1"
  }
}

resource "aws_cloudwatch_log_group" "my_second_log_group" {
  name              = var.name
  retention_in_days = 30
}

output "my_second_log_group_output" {
  value = {
    key    = aws_cloudwatch_log_group.my_second_log_group.name,
    arn    = aws_cloudwatch_log_group.my_second_log_group.arn,
    region = "us-east-1"
  }
}

module "log_forwarder_complete" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "=> 0.0.1"

  log_forwarder_lambda_function_name     = "log-forwarder"
  log_forwarder_lambda_region            = "us-east-1"
  log_forwarder_lambda_concurrency_limit = 1000
  log_forwarder_lambda_ttl               = 13
  log_forwarder_lambda_memory_size       = 128
  log_forwarder_lambda_log_level         = "INFO"

  lambda_enable_dashboard = true

  cloudwatch_log_group_subscriptions = [
    var.my_first_log_group_output,
    var.my_second_log_group_output
  ]

  cloudwatch_log_forward_filter_pattern = ""

  default_tags = {
    Terraform   = "true"
    Environment = "test"
    Service     = "log-forwarder"
  }

  elastic_search_url         = "192.168.0.1/_bulk"
  elastic_search_username    = "elastic-username"
  elastic_search_password    = "elastic-password"
  elastic_request_timeout_ms = 1000
  elastic_search_retry_count = 3
  elastic_search_index       = "my-index"
  elastic_allowed_log_fields = []
}
