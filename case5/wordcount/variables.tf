variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "casestudy-wordcount-bucket"
}

variable "project_name" {
  description = "Project prefix for naming"
  type        = string
  default     = "wordcount"
}
