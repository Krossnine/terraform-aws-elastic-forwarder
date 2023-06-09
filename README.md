# Terraform Aws Elastic Forwarder ![release](https://github.com/Krossnine/terraform-aws-elastic-forwarder/releases/latest) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


This Terraform module for provisioning a log forwarder for AWS CloudWatch Logs to ElasticSearch.

Included features :
- Automatically create Subscription for each CloudWatch Log Groups
- CloudWatch dashboard for lambda monitoring
- Multi region support
- Passive and active filtering of log events at subscription and lambda level
- Retry mechanism for failed log forward requests

:warning: You should to use an elastic `alias` instead of a pure `index` to avoid data loss when the index is rotated.

![test](https://github.com/Krossnine/terraform-aws-elastic-forwarder/actions/workflows/test-tf.yml/badge.svg)
![test](https://github.com/Krossnine/terraform-aws-elastic-forwarder/actions/workflows/test-lambda.yml/badge.svg)
![test](https://github.com/Krossnine/terraform-aws-elastic-forwarder/actions/workflows/build-lambda.yml/badge.svg)
![test](https://github.com/Krossnine/terraform-aws-elastic-forwarder/actions/workflows/integration-test.yml/badge.svg)

## Usage

### Simple example:

```hcl
module "log_forwarder" {
  source = "Krossnine/terraform-aws-elastic-forwarder"
  # version = "x.x.x"

  log_forwarder_lambda_region = var.region

  elastic_search_url      = var.elastic_search_url
  elastic_search_username = var.elastic_search_username
  elastic_search_password = var.elastic_search_password
  elastic_search_index    = var.elastic_search_index

  cloudwatch_log_group_subscriptions = [
    {
      key  = aws_cloudwatch_log_group.log_group.name
      arn   = aws_cloudwatch_log_group.log_group.arn
      region = aws_cloudwatch_log_group.log_group.region
    }
  ]
}
```

### Example with custom retry mechanism:

```hcl
module "log_forwarder" {
  source = "Krossnine/terraform-aws-elastic-forwarder"
  # version = "x.x.x"

  # The number of retry after the initial request
  elastic_search_retry_count = 4

  # The request time limit for the ELK request in milliseconds
  elastic_request_timeout_ms = 5000

  # The lambda timeout in seconds
  # eg:
  #   - ttl = Elk request ttl (in sec) * (Retry count + initial request) + cold start (in sec)
  #   - ttl = (elastic_request_timeout_ms / 1000) * (elastic_search_retry_count + 1) + 1
  #   - ttl = (5000 / 1000) * (4 + 1) + 1
  log_forwarder_lambda_ttl = 26
}
```

### Example with custom log filtering:

```hcl
module "log_forwarder" {
  source = "Krossnine/terraform-aws-elastic-forwarder"
  # version = "x.x.x"

  # Passive filtering at subscription level
  cloudwatch_log_forward_filter_pattern = "{ $.errorCode >= 400 }"

  # Active filtering at lambda level
  elastic_allowed_log_fields = [
    "message",
    "log.level",
    "my.nested.0.property"
  ]
}
```
## Dashboard preview :
![dashboard-demo](https://github.com/Krossnine/terraform-aws-elastic-forwarder/assets/6457707/7aac49a7-5990-4218-a45f-ddc90ff4d6a3)



<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.log_forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_subscription_filter.log_forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_iam_role.lambda_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.log_forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_cloudwatch_to_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.lambda_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_forward_filter_pattern"></a> [cloudwatch\_log\_forward\_filter\_pattern](#input\_cloudwatch\_log\_forward\_filter\_pattern) | (Optional) Defines the CloudWatch Logs filter pattern used<br>    to subscribe to a filtered stream of log events.<br>    An empty string matches all events.<br>    See the CloudWatch Logs User Guide for more information. | `string` | `""` | no |
| <a name="input_cloudwatch_log_group_subscriptions"></a> [cloudwatch\_log\_group\_subscriptions](#input\_cloudwatch\_log\_group\_subscriptions) | This variable is used to define a list of CloudWatch log groups<br>    with associated subscription filters. Each item in the list<br>    should include the ARN, ID, and name of a CloudWatch log group where a<br>    subscription filter will be added to send logs to the log forwarder<br>    Lambda function. | <pre>list(object({<br>    key    = string<br>    arn    = string<br>    region = string<br>  }))</pre> | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | The default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_elastic_allowed_log_fields"></a> [elastic\_allowed\_log\_fields](#input\_elastic\_allowed\_log\_fields) | The list of allowed log keys to forward to elastic search.<br>    If empty, all keys will be forwarded.<br>    This concern each keys in log events.<br>    To target specific nested properties in log events you can flatten them using the following syntax :<br>      - "key" to target the key property<br>      - "key.subkey" to target the subkey property<br><br>    Example: ["message", "log.level", "my.nested.0.property"] | `list(string)` | `[]` | no |
| <a name="input_elastic_request_timeout_ms"></a> [elastic\_request\_timeout\_ms](#input\_elastic\_request\_timeout\_ms) | The request time limit for the ELK request in milliseconds.<br>    Be aware that this is not the lambda timeout,<br>    Your need to orchestrate each of this variables accordingly :<br>      - log\_forwarder\_lambda\_ttl<br>      - elastic\_request\_timeout\_ms<br>      - elastic\_search\_retry\_count<br><br>    You can use the following formula to calculate the request timeout :<br>      elastic\_request\_timeout\_ms = (log\_forwarder\_lambda\_ttl - 1) * 1000 / (elastic\_search\_retry\_count + 1)<br>    Where :<br>      - log\_forwarder\_lambda\_ttl is the lambda timeout in seconds minus 1 second for the cold start<br>      - elastic\_search\_retry\_count is the number of retry plus the initial request<br><br>    Do not forget to add a gap to the lambda ttl for the initialization and the initial request before retries. | `number` | `3000` | no |
| <a name="input_elastic_search_index"></a> [elastic\_search\_index](#input\_elastic\_search\_index) | The elastic search index to use by default | `string` | n/a | yes |
| <a name="input_elastic_search_password"></a> [elastic\_search\_password](#input\_elastic\_search\_password) | The logstash password | `string` | n/a | yes |
| <a name="input_elastic_search_retry_count"></a> [elastic\_search\_retry\_count](#input\_elastic\_search\_retry\_count) | The logstash retries count before giving up<br>    Be aware to not set this value too high as it will be stopped by the lambda timeout.<br>    Your need to orchestrate each of this variables accordingly :<br>      - log\_forwarder\_lambda\_ttl<br>      - elastic\_request\_timeout\_ms<br>      - elastic\_search\_retry\_count<br><br>    You can use the following formula to calculate the retry count :<br>      elastic\_search\_retry\_count = Floor((log\_forwarder\_lambda\_ttl - 1) / (elastic\_request\_timeout\_ms / 1000))<br>    Where :<br>      - log\_forwarder\_lambda\_ttl is the lambda timeout in seconds minus 1 second for the cold start<br>      - elastic\_request\_timeout\_ms is the request timeout in milliseconds<br><br>    Do not forget to add a gap to the lambda ttl for the initialization and the initial request before retries. | `number` | `3` | no |
| <a name="input_elastic_search_url"></a> [elastic\_search\_url](#input\_elastic\_search\_url) | The elk / logstash url to forward logs to | `string` | n/a | yes |
| <a name="input_elastic_search_username"></a> [elastic\_search\_username](#input\_elastic\_search\_username) | The logstash username | `string` | n/a | yes |
| <a name="input_lambda_enable_dashboard"></a> [lambda\_enable\_dashboard](#input\_lambda\_enable\_dashboard) | Enable the lambda dashboard | `bool` | `true` | no |
| <a name="input_log_forwarder_lambda_concurrency_limit"></a> [log\_forwarder\_lambda\_concurrency\_limit](#input\_log\_forwarder\_lambda\_concurrency\_limit) | The maximum number of concurrent executions you want to reserve for the function.<br>    Set to -1 to allow unlimited concurrent executions.<br>    Set to 0 to disables lambda from being triggered.<br>    Set to 1 to disable parallel execution and only allow one lambda to run at a time.<br>    Set up to 1000 to reserve a fixed concurrency limit. | `number` | `-1` | no |
| <a name="input_log_forwarder_lambda_function_name"></a> [log\_forwarder\_lambda\_function\_name](#input\_log\_forwarder\_lambda\_function\_name) | Lambda configuration | `string` | `"cloudwatch-log-forwarder"` | no |
| <a name="input_log_forwarder_lambda_log_level"></a> [log\_forwarder\_lambda\_log\_level](#input\_log\_forwarder\_lambda\_log\_level) | The log level of the logger in lambda function | `string` | `"error"` | no |
| <a name="input_log_forwarder_lambda_memory_size"></a> [log\_forwarder\_lambda\_memory\_size](#input\_log\_forwarder\_lambda\_memory\_size) | The amount of memory the lambda function will be allocated (in MB) | `number` | `128` | no |
| <a name="input_log_forwarder_lambda_region"></a> [log\_forwarder\_lambda\_region](#input\_log\_forwarder\_lambda\_region) | The region where the lambda function will be deployed | `string` | n/a | yes |
| <a name="input_log_forwarder_lambda_ttl"></a> [log\_forwarder\_lambda\_ttl](#input\_log\_forwarder\_lambda\_ttl) | The maximum amount of time the lambda function will be allowed to run (in seconds).<br>    Be aware that this is not the request time limit for the ELK request.<br>    Your need to orchestrate each of this variables accordingly :<br>      - log\_forwarder\_lambda\_ttl<br>      - elastic\_request\_timeout\_ms<br>      - elastic\_search\_retry\_count<br><br>    You can use the following formula to calculate the lambda timeout :<br>      log\_forwarder\_lambda\_ttl = (elastic\_request\_timeout\_ms / 1000) * (elastic\_search\_retry\_count + 1) + 1<br>    Where :<br>      - elastic\_request\_timeout\_ms is the request timeout in milliseconds<br>      - elastic\_search\_retry\_count is the number of retry plus the initial request<br><br>    Do not forget to add a gap to the lambda ttl for the cold start and to the elastic\_search\_retry\_count for the initial request. | `number` | `13` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_dashboard"></a> [cloudwatch\_dashboard](#output\_cloudwatch\_dashboard) | The ARN of the cloudwatch dashboard |
| <a name="output_cloudwatch_subscriptions"></a> [cloudwatch\_subscriptions](#output\_cloudwatch\_subscriptions) | The info about the cloudwatch subscription |
| <a name="output_lambda_execution_role"></a> [lambda\_execution\_role](#output\_lambda\_execution\_role) | The ARN of the lambda execution role |
| <a name="output_lambda_function"></a> [lambda\_function](#output\_lambda\_function) | The ARN of the Lambda function that forwards logs to CloudWatch |
| <a name="output_lambda_function_role"></a> [lambda\_function\_role](#output\_lambda\_function\_role) | The ARN of the lambda IAM task execution role |
| <a name="output_log_subscription_permission"></a> [log\_subscription\_permission](#output\_log\_subscription\_permission) | The info of the invocation permission |
<!-- END_TF_DOCS -->
