# Lambda Task Execution Role
data "aws_iam_policy_document" "lambda_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_task_execution_role" {
  name               = "${var.log_forwarder_lambda_function_name}-lambdaTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_task_execution_role.json
  tags = merge(var.default_tags, {
    Type : "iam"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_task_execution_role" {
  role       = aws_iam_role.lambda_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# For each log group, allow cloudwatch to invoke the lambda function
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  count = length(var.cloudwatch_log_group_subscriptions)

  statement_id  = "${var.cloudwatch_log_group_subscriptions[count.index].key}-AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_forwarder.function_name
  principal     = "logs.${var.cloudwatch_log_group_subscriptions[count.index].region}.amazonaws.com"
  source_arn    = "${var.cloudwatch_log_group_subscriptions[count.index].arn}:*"
}
