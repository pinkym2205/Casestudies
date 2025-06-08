output "ec2_instance_1_public_ip" {
  description = "Public IP of EC2 instance in AZ1"
  value       = aws_instance.ec2_1.public_ip
}

output "ec2_instance_2_public_ip" {
  description = "Public IP of EC2 instance in AZ2"
  value       = aws_instance.ec2_2.public_ip
}

output "ec2_instance_3_public_ip" {
  description = "Public IP of EC2 instance in AZ3"
  value       = aws_instance.ec2_3.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for shared storage"
  value       = aws_s3_bucket.shared_bucket.id
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main_vpc.id
}
