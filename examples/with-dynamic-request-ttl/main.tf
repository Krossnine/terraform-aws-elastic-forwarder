resource "aws_cloudwatch_log_group" "my_log_group" {
  name              = var.name
  retention_in_days = 30
}

locals {
  request_timeout = (var.log_forwarder_lambda_ttl - 1) / (var.retry + 1) * 1000
}

module "log_forwarder" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "=> 0.0.1"

  elastic_request_timeout_ms = local.request_timeout
  elastic_search_retry_count = var.retry                    // 4
  log_forwarder_lambda_ttl   = var.log_forwarder_lambda_ttl // 13

  log_forwarder_lambda_region = "us-east-1"
  elastic_search_url          = "http://192.168.0.1/_bulk"
  elastic_search_username     = "elastic-username"
  elastic_search_password     = "elastic-password"
  elastic_search_index        = "my-index"
  cloudwatch_log_group_subscriptions = [{
    key    = aws_cloudwatch_log_group.my_log_group.name,
    arn    = aws_cloudwatch_log_group.my_log_group.arn,
    region = "us-east-1"
  }]
}
