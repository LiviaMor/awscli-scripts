# ==========================================
# ALB
# ==========================================
resource "aws_lb" "bia" {
  name               = "bia-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.bia_alb.id]
  subnets            = var.subnets
}

# ==========================================
# Target Group (ECS containers)
# ==========================================
resource "aws_lb_target_group" "bia" {
  name        = "bia-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

# ==========================================
# Listener HTTPS (443) → Target Group
# ==========================================
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.bia.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.bia.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bia.arn
  }
}

# ==========================================
# Listener HTTP (80) → Redirect HTTPS
# ==========================================
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.bia.arn
  port              = 80
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
