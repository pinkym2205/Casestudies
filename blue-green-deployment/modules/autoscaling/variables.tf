variable "environment" {}
variable "vpc_id" {}
variable "alb_target_group_arn" {}
variable "instance_ami" {}
variable "instance_type" { default = "t3.micro" }
variable "key_name" {}
variable "desired_capacity" { default = 2 }
variable "min_size" { default = 1 }
variable "max_size" { default = 3 }
variable "public_subnets"  {type = list(string)}
