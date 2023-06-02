resource "aws_cloudwatch_dashboard" "log_forwarder" {
  count          = var.lambda_enable_dashboard ? 1 : 0
  dashboard_name = "${var.log_forwarder_lambda_function_name}-overview"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 3,
        "width" : 5,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", var.log_forwarder_lambda_function_name, { "region" : var.log_forwarder_lambda_region, "label" : "From $${FIRST_TIME_RELATIVE}", "color" : "#2ca02c" }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "period" : 60,
          "stat" : "Sum",
          "title" : " Total Invocations",
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 3,
        "width" : 5,
        "y" : 0,
        "x" : 5,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", var.log_forwarder_lambda_function_name, { "color" : "#d62728", "region" : var.log_forwarder_lambda_region }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "Sum",
          "period" : 300,
          "setPeriodToTimeRange" : true,
          "trend" : false,
          "liveData" : true,
          "title" : "Errors"
        }
      },
      {
        "height" : 3,
        "width" : 5,
        "y" : 0,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "sparkline" : false,
          "view" : "singleValue",
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", var.log_forwarder_lambda_function_name, { "region" : var.log_forwarder_lambda_region }]
          ],
          "region" : var.log_forwarder_lambda_region,
          "setPeriodToTimeRange" : true,
          "trend" : false,
          "singleValueFullPrecision" : false,
          "liveData" : true,
          "title" : "Avg. Duration",
          "period" : 300
        }
      },
      {
        "height" : 3,
        "width" : 5,
        "y" : 0,
        "x" : 15,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Throttles", "FunctionName", var.log_forwarder_lambda_function_name, { "color" : "#ffbb78" }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "setPeriodToTimeRange" : true,
          "trend" : false,
          "stat" : "Sum",
          "period" : 300,
          "title" : "Total Throttles"
        }
      },
      {
        "height" : 5,
        "width" : 4,
        "y" : 0,
        "x" : 20,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "( m2 * 100) / m1", "label" : "Error rate (%)", "id" : "e1", "color" : "#d62728" }],
            ["AWS/Lambda", "Invocations", "FunctionName", var.log_forwarder_lambda_function_name, { "id" : "m1", "visible" : false }],
            [".", "Errors", ".", ".", { "id" : "m2", "visible" : false }]
          ],
          "view" : "gauge",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "Sum",
          "period" : 300,
          "yAxis" : {
            "left" : {
              "min" : 0,
              "max" : 100
            }
          },
          "setPeriodToTimeRange" : true,
          "sparkline" : false,
          "trend" : false,
          "title" : "% Error"
        }
      },
      {
        "height" : 4,
        "width" : 10,
        "y" : 3,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", var.log_forwarder_lambda_function_name, { "region" : var.log_forwarder_lambda_region, "color" : "#2ca02c" }]
          ],
          "view" : "timeSeries",
          "stacked" : true,
          "region" : var.log_forwarder_lambda_region,
          "period" : 300,
          "stat" : "Sum",
          "title" : "Invocations [5m]"
        }
      },
      {
        "height" : 4,
        "width" : 10,
        "y" : 7,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "ANOMALY_DETECTION_BAND(m0, 1)", "label" : "Expression1", "id" : "e1", "color" : "#e7e7e7", "region" : var.log_forwarder_lambda_region }],
            ["AWS/Lambda", "Duration", "FunctionName", var.log_forwarder_lambda_function_name, { "id" : "m0", "region" : var.log_forwarder_lambda_region, "color" : "#1f77b4" }]
          ],
          "legend" : {
            "position" : "bottom"
          },
          "period" : 300,
          "view" : "timeSeries",
          "stacked" : true,
          "title" : "Duration [5m]",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "Average"
        }
      },
      {
        "height" : 4,
        "width" : 10,
        "y" : 3,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", var.log_forwarder_lambda_function_name, { "id" : "m0", "region" : var.log_forwarder_lambda_region, "color" : "#d62728" }]
          ],
          "legend" : {
            "position" : "bottom"
          },
          "period" : 300,
          "view" : "timeSeries",
          "stacked" : true,
          "title" : "Errors [5m]",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "Sum"
        }
      },
      {
        "height" : 4,
        "width" : 10,
        "y" : 7,
        "x" : 10,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Throttles", "FunctionName", var.log_forwarder_lambda_function_name, { "id" : "m0", "region" : var.log_forwarder_lambda_region, "color" : "#ffbb78" }]
          ],
          "legend" : {
            "position" : "bottom"
          },
          "period" : 300,
          "view" : "timeSeries",
          "stacked" : true,
          "title" : "Throttles [5m]",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "Sum"
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 5,
        "x" : 20,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", var.log_forwarder_lambda_function_name, { "label" : "Duration p50" }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "p50",
          "period" : 300,
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 8,
        "x" : 20,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", var.log_forwarder_lambda_function_name, { "label" : "Duration p90", "region" : var.log_forwarder_lambda_region }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "p90",
          "period" : 300,
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 3,
        "width" : 4,
        "y" : 11,
        "x" : 20,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", var.log_forwarder_lambda_function_name, { "label" : "Duration p99.9", "region" : var.log_forwarder_lambda_region }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "region" : var.log_forwarder_lambda_region,
          "stat" : "p99.9",
          "period" : 300,
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 6,
        "width" : 5,
        "y" : 11,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "SELECT SUM(DeadLetterErrors) FROM SCHEMA(\"AWS/Lambda\", FunctionName)", "label" : "Dead-letter Errors", "id" : "q1" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.log_forwarder_lambda_region,
          "period" : 300,
          "stat" : "Average",
          "title" : "Dead-Letter Errors"
        }
      },
      {
        "height" : 6,
        "width" : 5,
        "y" : 11,
        "x" : 5,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [{ "expression" : "SELECT SUM(DestinationDeliveryFailures) FROM SCHEMA(\"AWS/Lambda\", FunctionName)", "label" : "Dead-letter Errors", "id" : "q1", "region" : var.log_forwarder_lambda_region }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.log_forwarder_lambda_region,
          "period" : 300,
          "stat" : "Average",
          "title" : "Destination Delivery Failures"
        }
      },
      {
        "type" : "log",
        "x" : 10,
        "y" : 11,
        "width" : 10,
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${var.log_forwarder_lambda_function_name}' | filter @type = \"REPORT\"\n| parse @message /Init Duration: (?<init>\\S+)/ |\n| stats count() as total, count(init) as coldStarts, median(init) as avgInitDuration, max(init) as maxInitDuration, avg(@maxMemoryUsed)/1000/1000 as memoryused by bin (5m)",
          "region" : var.log_forwarder_lambda_region,
          "stacked" : false,
          "view" : "timeSeries",
          "title" : "Cold vs Warm Start"
        }
      },
      {
        "type" : "log",
        "x" : 0,
        "y" : 17,
        "width" : 10,
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${var.log_forwarder_lambda_function_name}' | filter @type = \"REPORT\"\n| stats max(@memorySize / 1000 / 1000) as provisonedMemoryMB,\n  min(@maxMemoryUsed / 1000 / 1024) as smallestMemoryRequestMB,\n  avg(@maxMemoryUsed / 1024 / 1024) as avgMemoryUsedMB,\n  max(@maxMemoryUsed / 1024 / 1024) as maxMemoryUsedMB,\n  provisonedMemoryMB - maxMemoryUsedMB as overProvisionedMB by bin (5m)",
          "region" : var.log_forwarder_lambda_region,
          "stacked" : false,
          "title" : "Memory consumption",
          "view" : "timeSeries"
        }
      },
      {
        "type" : "log",
        "x" : 10,
        "y" : 17,
        "width" : 10,
        "height" : 6,
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${var.log_forwarder_lambda_function_name}' | filter @type = \"REPORT\"\n| stats max(@billedDuration) as maxBilledDuration by bin(5m)",
          "region" : var.log_forwarder_lambda_region,
          "stacked" : true,
          "title" : "Max Billed Duration [5m]",
          "view" : "timeSeries"
        }
      }
    ]
  })
}
