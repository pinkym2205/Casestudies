# Root Terraform Configuration for Blue/Green Deployment

# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "network" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  azs                = var.azs
  enable_nat_gateway = false
  single_nat_gateway = false
}

# ACM Certificate
module "acm" {
  source         = "./modules/acm"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

# ALB for Blue Environment
module "alb_blue" {
  source            = "./modules/alb"
  environment       = "blue"
  vpc_id            = module.network.vpc_id
  public_subnets    = module.network.public_subnets
  certificate_arn   = module.acm.certificate_arn
  target_group_name = "blue-tg"
}

# ALB for Green Environment
module "alb_green" {
  source            = "./modules/alb"
  environment       = "green"
  vpc_id            = module.network.vpc_id
  public_subnets    = module.network.public_subnets
  certificate_arn   = module.acm.certificate_arn
  target_group_name = "green-tg"
}

# Auto Scaling Group - Blue
module "asg_blue" {
  source               = "./modules/autoscaling"
  environment          = "blue"
  vpc_id               = module.network.vpc_id
  public_subnets       = module.network.public_subnets
  alb_target_group_arn = module.alb_blue.target_group_arn
  instance_ami         = var.blue_ami
  key_name             = var.key_name
}

# Auto Scaling Group - Green
module "asg_green" {
  source               = "./modules/autoscaling"
  environment          = "green"
  vpc_id               = module.network.vpc_id
  public_subnets       = module.network.public_subnets
  alb_target_group_arn = module.alb_green.target_group_arn
  instance_ami         = var.green_ami
  key_name             = var.key_name
}

# Route53 DNS Records
module "route53" {
  source         = "./modules/route53"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  alb_blue_dns   = module.alb_blue.dns_name
  alb_green_dns  = module.alb_green.dns_name
  alb_blue_zone_id = module.alb_blue.zone_id
  alb_green_zone_id = module.alb_green.zone_id
}


