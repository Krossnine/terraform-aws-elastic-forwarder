output "lambda_function" {
  value       = aws_lambda_function.log_forwarder.arn
  description = "The ARN of the Lambda function that forwards logs to CloudWatch"
}

output "lambda_log_group" {
  value       = aws_cloudwatch_log_group.forwarder_log_group.arn
  description = "The ARN of the Lambda log group"
}

output "cloudwatch_subscriptions" {
  value       = aws_cloudwatch_log_subscription_filter.log_forwarder[*]
  description = "The info about the cloudwatch subscription"
}

output "lambda_execution_role" {
  value       = aws_iam_role.lambda_task_execution_role.arn
  description = "The ARN of the lambda execution role"
}

output "lambda_function_role" {
  value       = aws_iam_role.lambda_task_execution_role.arn
  description = "The ARN of the lambda IAM task execution role"
}

output "log_subscription_permission" {
  value       = aws_lambda_permission.allow_cloudwatch_to_invoke[*]
  description = "The info of the invocation permission"
}

output "cloudwatch_dashboard" {
  value       = aws_cloudwatch_dashboard.log_forwarder[0].dashboard_arn
  description = "The ARN of the cloudwatch dashboard"
}
