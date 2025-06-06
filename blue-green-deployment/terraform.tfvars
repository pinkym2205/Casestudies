# AWS region to deploy resources
aws_region = "us-east-1"

# VPC CIDR block
vpc_cidr = "10.2.0.0/16"

# Public subnets in two AZs
public_subnets = [
  "10.2.1.0/24",
  "10.2.2.0/24"
]

# Private subnets in two AZs
private_subnets = [
  "10.2.11.0/24",
  "10.2.12.0/24"
]

# Availability zones
azs = [
  "us-east-1a",
  "us-east-1b"
]

# Domain name registered in Route53
domain_name = "test-bg.xyz"

# Hosted zone ID for the domain (find it in Route53 under the hosted zone)
hosted_zone_id = "Z03319603TTDJ13DX5MOG"

# AMI ID for Blue environment (e.g., Amazon Linux 2)
blue_ami = "ami-0a7d80731ae1b2435"

# AMI ID for Green environment
green_ami = "ami-0a7d80731ae1b2435"

key_name = "mykeypair"


