variable "region" {
  default = "us-east-1"
}

variable "instance_ids" {
  type        = list(string)
  description = "List of EC2 instance IDs to manage"
}

variable "lambda_function_name" {
  default = "ec2-start-stop"
}
