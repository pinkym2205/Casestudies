output "blue_alb_dns" {
  description = "DNS name of the Blue ALB"
  value       = module.alb_blue.dns_name
}

output "green_alb_dns" {
  description = "DNS name of the Green ALB"
  value       = module.alb_green.dns_name
}

output "blue_asg_name" {
  description = "Name of the Auto Scaling Group for Blue"
  value       = module.asg_blue.asg_name
}

output "green_asg_name" {
  description = "Name of the Auto Scaling Group for Green"
  value       = module.asg_green.asg_name
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.acm.certificate_arn
}
