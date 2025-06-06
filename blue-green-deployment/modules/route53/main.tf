resource "aws_route53_record" "blue" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_blue_dns
    zone_id                = var.alb_blue_zone_id
    evaluate_target_health = true
  }

  set_identifier = "blue"
  weighted_routing_policy {
    weight = var.blue_weight
  }
}

resource "aws_route53_record" "green" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"   

  alias {
    name                   = var.alb_green_dns
    zone_id                = var.alb_green_zone_id
    evaluate_target_health = true
  }

  set_identifier = "green"
  weighted_routing_policy {
    weight = var.green_weight
  }
}