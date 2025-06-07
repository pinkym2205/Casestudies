provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project_name}_s3_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "word_counter" {
  function_name    = "${var.project_name}_word_counter"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.word_counter.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "out/"
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.word_counter.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}
