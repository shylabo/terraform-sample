resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application" // networkを指定するとNLB
  internal                   = false         //インターネット向けの場合はfalse
  idle_timeout               = 60            // default value
  enable_deletion_protection = false         // 検証のため便宜上false
  # enable_deletion_protection = true          // 本番環境では誤って削除されないように保護しておく

  // 負荷分散
  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

# ***************************
# HTTP Listener
# ***************************
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP" //ALBはHTTPとHTTPSのみをサポート

  // いずれのルールにも合致しない場合
  default_action {
    type = "fixed-response"
    // type=forward:リクエストを別のターゲットグループに転送
    // type=fixed-response:別のURLにリダイレクト
    // type=redirect:別のURLにリダイレクト

    fixed_response {
      content_type = "text/plain"
      message_body = "This is HTTP"
      status_code  = "200"
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}

# ***************************
# HTTPS Listener
# ***************************
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.example.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is HTTPS"
      status_code  = "200"
    }
  }
}

# ***************************
# Redirect Listener
# ***************************
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ***************************
# Request forwarding
# ***************************
resource "aws_lb_target_group" "example" {
  name                 = "example"
  target_type          = "ip" // EC2インスタンスやIPアドレス、Lambda関数を指定できる。ECS Fargateの場合はipを指定
  vpc_id               = aws_vpc.example.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300 //ターゲット登録解除前のALBが待機する時間（default 300）

  health_check {
    path                = "/"
    healthy_threshold   = 5              // 正常判定までのヘルスチェック実行回数
    unhealthy_threshold = 2              // 異常判定までのヘルスチェック実行回数
    timeout             = 5              // ヘルスチェックのタイムアウト時間
    interval            = 30             // ヘルスチェックの実行間隔
    matcher             = 200            //正常判定を行うために使用するHTTPステータスコード
    port                = "traffic-port" //ヘルスチェックで使用するポート
    protocol            = "HTTP"         //ヘルスチェック時に使用するプロトコル
  }

  depends_on = [aws_lb.example] //ALBとターゲットグループをECSと同時作成するとエラーになるので依存関係を制御する必要あり
}

resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100 // 数字が小さいほどpriorityが高い（デフォルトルールは最も優先順位が低い）

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}
