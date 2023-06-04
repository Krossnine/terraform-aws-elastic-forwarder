resource "aws_cloudwatch_log_group" "my_log_group" {
  name              = var.name
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "another_log_group" {
  name              = var.name
  retention_in_days = 30
}

output "another_log_group_info" {
  value = {
    key    = aws_cloudwatch_log_group.another_log_group.name,
    arn    = aws_cloudwatch_log_group.another_log_group.arn,
    region = "us-east-1"
  }
}

module "dynamic_module_with_log_group" {
  provider = null

  count = length(local.log_groups)
}

module "log_forwarder_minimal" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "=> 0.0.1"

  cloudwatch_log_group_subscriptions = concat(
    [
      {
        key    = aws_cloudwatch_log_group.my_log_group.name,
        arn    = aws_cloudwatch_log_group.my_log_group.arn,
        region = "us-east-1"
      },
      another_log_group_info
    ],
    module.dynamic_module_with_log_group[*].logs
  )

  log_forwarder_lambda_region = "us-east-1"
  elastic_search_url          = "http://192.168.0.1/_bulk"
  elastic_search_username     = "elastic-username"
  elastic_search_password     = "elastic-password"
  elastic_search_index        = "my-index"
}
