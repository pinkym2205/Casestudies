output "blue_record_fqdn" {
  value = aws_route53_record.blue.fqdn
}

output "green_record_fqdn" {
  value = aws_route53_record.green.fqdn
}
#output "zone_id" {
 # value = aws_lb.this.zone_id
#}
