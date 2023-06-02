output "log_forwarder_lambda_arn" {
  value       = aws_lambda_function.log_forwarder.arn
  description = "The ARN of the Lambda function that forwards logs to CloudWatch"
}

output "cloudwatch_subscriptions" {
  value       = aws_lambda_function.log_forwarder.arn
  description = "The ARN of the cloudwatch subscription filters"
}
