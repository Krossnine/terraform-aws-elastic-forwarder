resource "aws_lambda_function" "log_forwarder" {
  function_name = var.log_forwarder_lambda_function_name
  role          = aws_iam_role.lambda_task_execution_role.arn

  runtime  = "nodejs18.x"
  handler  = "app.handler"
  filename = "${path.module}/lambda/lambda.zip"

  source_code_hash = filebase64sha256("./${path.module}/lambda/lambda.zip")

  timeout                        = var.log_forwarder_lambda_ttl
  memory_size                    = var.log_forwarder_lambda_memory_size
  reserved_concurrent_executions = var.log_forwarder_lambda_concurrency_limit

  description = "This lambda function is used to forward logs from CloudWatch to ElasticSearch."

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ELASTIC_ALLOWED_LOG_FIELDS = join(",", var.elastic_allowed_log_fields)
      ELASTIC_SEARCH_INDEX       = var.elastic_search_index
      ELASTIC_SEARCH_PASSWORD    = var.elastic_search_password
      ELASTIC_SEARCH_RETRY_COUNT = var.elastic_search_retry_count
      ELASTIC_SEARCH_URL         = var.elastic_search_url
      ELASTIC_SEARCH_USERNAME    = var.elastic_search_username
      LOG_LEVEL                  = var.log_forwarder_lambda_log_level
      REQUEST_TIMEOUT_MS         = var.elastic_request_timeout_ms
    }
  }
}
