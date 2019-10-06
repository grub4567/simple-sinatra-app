#
# Terraform output
#

output "domain" {
  value = aws_lb.alb.dns_name
}
