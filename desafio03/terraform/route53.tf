# ==========================================
# Route53: domínio → ALB
# ==========================================
resource "aws_route53_record" "bia" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.bia.dns_name
    zone_id                = aws_lb.bia.zone_id
    evaluate_target_health = true
  }
}
