provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "certs"
  region                  = "us-east-1"
}

resource "aws_acm_certificate" "default"{
  domain_name       = var.domain
  validation_method = "DNS"

  tags = {
    Name = var.domain
    Environment = var.env
    CreatedTime = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "default" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zoneid
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.default : record.fqdn]
}
