data "aws_route53_zone" "example" {
  name = "example.com"
}

// 新規ホストゾーン作成
resource "aws_route53_zone" "test_example" {
  name = "test.example.com"
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = data.aws_route53_zone.example.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.example.name
}

# ***************************
# AWS Certificate Manager
# ***************************
resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_record.example.name // *.example.comにするとワイルドカード証明書を発行可能
  subject_alternative_names = []                              //ドメイン名の追加（サブドメイン等）
  validation_method         = "DNS"                           //Eめーる検証もできるが、SSL証明書の自動更新をしたい場合はDNS検証のみ

  // ライフサイクルはTerraform独自の機能。通常は削除->作成になるが、逆を実現できる
  lifecycle {
    create_before_destroy = true //新しいSSL証明書を作成してから差し替え
  }
}

resource "aws_route53_record" "example_certificate" {
  name    = aws_acm_certificate.example.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.example.domain_validation_options[0].resource_record_value]

  zone_id = data.aws_route53_zone.example.id
  ttl     = 60
}

// apply時にSSL証明書の検証が完了するまで待ってくれる（何かリソースを作るわけではない）
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [aws_route53_record.example_certificate.fqdn]
}
