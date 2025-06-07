provider "aws" {
  region = var.region
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_ec2_start_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "ec2_start_stop" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# Stop Rule 
resource "aws_cloudwatch_event_rule" "stop_rule" {
  name                = "stop-ec2-daily"
  schedule_expression = "cron(30 12 * * ? *)"  # 12:30 AM UTC = 6:00 PM IST
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_rule.name
  target_id = "lambdaStop"
  arn       = aws_lambda_function.ec2_start_stop.arn
  input = jsonencode({
    ACTION       = "stop",
    INSTANCE_IDS = join(",", var.instance_ids)
  })
}

# Start Rule 
resource "aws_cloudwatch_event_rule" "start_rule" {
  name                = "start-ec2-daily"
  schedule_expression = "cron(30 3 * * ? *)"  # 3:30AM UTC = 9:00 AM IST
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_rule.name
  target_id = "lambdaStart"
  arn       = aws_lambda_function.ec2_start_stop.arn
  input = jsonencode({
    ACTION       = "start",
    INSTANCE_IDS = join(",", var.instance_ids)
  })
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_stop_event" {
  statement_id  = "AllowStopEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rule.arn
}

resource "aws_lambda_permission" "allow_start_event" {
  statement_id  = "AllowStartEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rule.arn
}
