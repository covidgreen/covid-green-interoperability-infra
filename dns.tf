# #########################################
# Route53 zone
# #########################################
data "aws_route53_zone" "primary" {
  count        = local.enable_dns_count
  provider     = aws.root
  name         = var.route53_zone
  private_zone = false
}

# #########################################
# DNS Records
# #########################################
resource "aws_route53_record" "interop" {
  count    = local.enable_dns_count
  provider = aws.root
  zone_id  = data.aws_route53_zone.primary[0].id
  name     = var.interop_dns
  type     = "A"

  alias {
    name                   = aws_api_gateway_domain_name.main[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.main[0].cloudfront_zone_id
    evaluate_target_health = true
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_domain_name.main
  ]
}
