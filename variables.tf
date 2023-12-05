# Lambda configuration
variable "log_forwarder_lambda_function_name" {
  type    = string
  default = "cloudwatch-log-forwarder"
}

variable "log_forwarder_lambda_region" {
  type        = string
  description = "The region where the lambda function will be deployed"
}

variable "log_forwarder_lambda_concurrency_limit" {
  type        = number
  default     = -1
  description = <<EOF
    The maximum number of concurrent executions you want to reserve for the function.
    Set to -1 to allow unlimited concurrent executions.
    Set to 0 to disables lambda from being triggered.
    Set to 1 to disable parallel execution and only allow one lambda to run at a time.
    Set up to 1000 to reserve a fixed concurrency limit.
  EOF

  validation {
    condition     = var.log_forwarder_lambda_concurrency_limit >= -1 && var.log_forwarder_lambda_concurrency_limit <= 1000
    error_message = "The lambda concurrency limit must be greater or equal to -1 and less or equal to 1000"
  }
}

variable "log_forwarder_lambda_ttl" {
  type    = number
  default = 13

  description = <<EOF
    The maximum amount of time the lambda function will be allowed to run (in seconds).
    Be aware that this is not the request time limit for the ELK request.
    Your need to orchestrate each of this variables accordingly :
      - log_forwarder_lambda_ttl
      - elastic_request_timeout_ms
      - elastic_search_retry_count

    You can use the following formula to calculate the lambda timeout :
      log_forwarder_lambda_ttl = (elastic_request_timeout_ms / 1000) * (elastic_search_retry_count + 1) + 1
    Where :
      - elastic_request_timeout_ms is the request timeout in milliseconds
      - elastic_search_retry_count is the number of retry plus the initial request

    Do not forget to add a gap to the lambda ttl for the cold start and to the elastic_search_retry_count for the initial request.
  EOF

  validation {
    condition     = var.log_forwarder_lambda_ttl > 0 && var.log_forwarder_lambda_ttl <= 900
    error_message = "The lambda timeout must be between 1 and 900"
  }
}

variable "log_forwarder_lambda_memory_size" {
  type        = number
  default     = 128
  description = "The amount of memory the lambda function will be allocated (in MB)"
  validation {
    condition     = var.log_forwarder_lambda_memory_size >= 128 && var.log_forwarder_lambda_memory_size <= 10240
    error_message = "The lambda memory must be between 128 and 10240"
  }
}

variable "log_forwarder_lambda_log_level" {
  type        = string
  default     = "error"
  description = "The log level of the logger in lambda function"

  validation {
    condition     = contains(["fatal", "error", "warn", "info", "debug", "trace"], var.log_forwarder_lambda_log_level)
    error_message = <<EOF
      The lambda log level must be one of the following values :
        - fatal
        - error
        - warn
        - info
        - debug
        - trace

      In production, it is recommended to set the log level to error.
    EOF
  }
}

variable "lambda_enable_dashboard" {
  type        = bool
  default     = true
  description = "Enable the lambda dashboard"
}

# CloudWatch log subscriptions
variable "cloudwatch_log_group_subscriptions" {
  type = list(object({
    key    = string
    arn    = string
    region = string
  }))

  description = <<EOF
    This variable is used to define a list of CloudWatch log groups
    with associated subscription filters. Each item in the list
    should include the ARN, Name, and region of a CloudWatch log group where a
    subscription filter will be added to send logs to the log forwarder
    Lambda function.
  EOF
}

# Log forwarding configuration
variable "cloudwatch_log_forward_filter_pattern" {
  type        = string
  default     = ""
  description = <<EOF
    (Optional) Defines the CloudWatch Logs filter pattern used
    to subscribe to a filtered stream of log events.
    An empty string matches all events.
    See the CloudWatch Logs User Guide for more information.
  EOF
}

# Default tags
variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "The default tags to apply to all resources"
}

# Elastic search configuration
variable "elastic_search_url" {
  type        = string
  description = "The elk / logstash url to forward logs to"
}

variable "elastic_search_username" {
  type        = string
  description = "The logstash username"
  sensitive   = true
}

variable "elastic_search_password" {
  type        = string
  description = "The logstash password"
  sensitive   = true
}

variable "elastic_request_timeout_ms" {
  type        = number
  default     = 3000
  description = <<EOF
    The request time limit for the ELK request in milliseconds.
    Be aware that this is not the lambda timeout,
    Your need to orchestrate each of this variables accordingly :
      - log_forwarder_lambda_ttl
      - elastic_request_timeout_ms
      - elastic_search_retry_count

    You can use the following formula to calculate the request timeout :
      elastic_request_timeout_ms = (log_forwarder_lambda_ttl - 1) * 1000 / (elastic_search_retry_count + 1)
    Where :
      - log_forwarder_lambda_ttl is the lambda timeout in seconds minus 1 second for the cold start
      - elastic_search_retry_count is the number of retry plus the initial request

    Do not forget to add a gap to the lambda ttl for the initialization and the initial request before retries.
  EOF

  validation {
    condition     = var.elastic_request_timeout_ms > 0 && var.elastic_request_timeout_ms <= 900000
    error_message = "The logstash timeout must be between 1 and 900"
  }
}

variable "elastic_search_retry_count" {
  type        = number
  default     = 3
  description = <<EOF
    The logstash retries count before giving up
    Be aware to not set this value too high as it will be stopped by the lambda timeout.
    Your need to orchestrate each of this variables accordingly :
      - log_forwarder_lambda_ttl
      - elastic_request_timeout_ms
      - elastic_search_retry_count

    You can use the following formula to calculate the retry count :
      elastic_search_retry_count = Floor((log_forwarder_lambda_ttl - 1) / (elastic_request_timeout_ms / 1000))
    Where :
      - log_forwarder_lambda_ttl is the lambda timeout in seconds minus 1 second for the cold start
      - elastic_request_timeout_ms is the request timeout in milliseconds

    Do not forget to add a gap to the lambda ttl for the initialization and the initial request before retries.
  EOF

  validation {
    condition     = var.elastic_search_retry_count >= 0
    error_message = "The logstash retries must be positive or null"
  }
}

variable "elastic_search_index" {
  type        = string
  description = "The elastic search index to use by default"
}

variable "elastic_allowed_log_fields" {
  type        = list(string)
  default     = []
  description = <<EOF
    The list of allowed log keys to forward to elastic search.
    If empty, all keys will be forwarded.
    This concern each keys in log events.
    To target specific nested properties in log events you can flatten them using the following syntax :
      - "key" to target the key property
      - "key.subkey" to target the subkey property

    Example: ["message", "log.level", "my.nested.0.property"]
  EOF
}
