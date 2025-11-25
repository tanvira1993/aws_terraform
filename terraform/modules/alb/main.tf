# ============================================================================
# Application Load Balancer
# ============================================================================

resource "aws_lb" "main" {
  name               = "${substr(var.project_name, 0, 8)}-${substr(var.environment, 0, 4)}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# ============================================================================
# Target Group for Jenkins
# ============================================================================

resource "aws_lb_target_group" "jenkins" {
  name     = "${substr(var.project_name, 0, 8)}-${substr(var.environment, 0, 4)}-jenkins"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/login"
    matcher             = "200,302"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-jenkins-tg"
    }
  )
}

# ============================================================================
# Target Group Attachment for Jenkins
# ============================================================================

resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = var.jenkins_instance_id
  port             = 8080
}

# ============================================================================
# Target Group for EKS (API/Application)
# ============================================================================

resource "aws_lb_target_group" "eks" {
  name     = "${substr(var.project_name, 0, 8)}-${substr(var.environment, 0, 4)}-eks"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200,404"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-tg"
    }
  )
}

# ============================================================================
# HTTP Listener (Always created)
# ============================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = var.enable_https ? "redirect" : "forward"
    target_group_arn = var.enable_https ? null : aws_lb_target_group.eks.arn

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# ============================================================================
# HTTP Listener Rule for Jenkins
# ============================================================================

resource "aws_lb_listener_rule" "jenkins_http" {
  count = var.enable_https ? 0 : 1

  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  condition {
    host_header {
      values = var.domain_name != "" ? ["jenkins.${var.domain_name}"] : ["*"]
    }
  }
}

# ============================================================================
# HTTPS Listener (if certificate provided)
# ============================================================================

resource "aws_lb_listener" "https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks.arn
  }
}

# ============================================================================
# HTTPS Listener Rule for Jenkins
# ============================================================================

resource "aws_lb_listener_rule" "jenkins_https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  condition {
    host_header {
      values = var.domain_name != "" ? ["jenkins.${var.domain_name}"] : ["*"]
    }
  }
}

