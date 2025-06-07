provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/delete_old_snapshots.py"
  output_path = "${path.module}/lambda/delete_old_snapshots.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-ebs-snapshot-cleanup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy" "lambda_snapshot_policy" {
  name = "lambda-ebs-snapshot-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_snapshot_policy.arn
}

resource "aws_lambda_function" "ebs_snapshot_cleanup" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ebs-snapshot-cleanup"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "delete_old_snapshots.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 60
}

resource "aws_cloudwatch_event_rule" "weekly_trigger" {
  name                = "weekly-ebs-snapshot-cleanup"
  schedule_expression = "cron(0 6 ? * 1 *)" # Every Monday at 6:00 UTC
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_trigger.name
  target_id = "ebs-snapshot-cleanup-lambda"
  arn       = aws_lambda_function.ebs_snapshot_cleanup.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_snapshot_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_trigger.arn
}
