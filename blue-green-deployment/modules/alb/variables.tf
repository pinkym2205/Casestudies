variable "environment" {}
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "certificate_arn" {}
variable "target_group_name" {}