output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.word_counter.function_name
}
