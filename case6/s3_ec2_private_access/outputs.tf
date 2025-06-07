output "bucket_name" {
  value = aws_s3_bucket.image_bucket.bucket
}

output "instance_id" {
  value = aws_instance.app.id
}
