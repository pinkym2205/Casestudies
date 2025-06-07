variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "secure-private-s3-bucket-case"
}

variable "ami_id" {
  description = "AMI ID for EC2"
}

variable "instance_type" {
  default = "t3.micro"
}
variable "key_name" {
  type    = string
  default = "ec2-access-key"
}

