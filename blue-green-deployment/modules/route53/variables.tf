variable "domain_name" {}
variable "hosted_zone_id" {}
variable "alb_blue_dns" {}
variable "alb_green_dns" {}
variable "alb_blue_zone_id" {}
variable "alb_green_zone_id" {}
variable "blue_weight" { default = 80 }
variable "green_weight" { default = 20 }