# Application Load Balancer Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}



# Application Load Balancer
resource "aws_lb" "app" {
  name               = trimsuffix(substr("${var.environment}-${var.name}", 0, 24), "-") # max 24 chars, no trailing hyphen
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  enable_http2              = true
  idle_timeout             = 60

  # Enable access logs if bucket is provided
  dynamic "access_logs" {
    for_each = var.log_bucket != "" ? [1] : []
    content {
      bucket  = var.log_bucket
      prefix  = "alb-logs"
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-alb"
  })
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name_prefix = "fe-"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  stickiness {
    type            = "app_cookie"
    cookie_name     = "session"
    cookie_duration = 86400
    enabled         = true
  }

  # Deregistration delay
  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-frontend-tg"
  })
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name_prefix = "be-"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    port                = "8000"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  stickiness {
    type            = "app_cookie"
    cookie_name     = "session"
    cookie_duration = 86400
    enabled         = true
  }

  # Deregistration delay
  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-backend-tg"
  })
}

# Frontend Listener (HTTP)
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Backend Listener
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.app.arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Frontend Target Group Attachment
resource "aws_lb_target_group_attachment" "frontend" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = var.instance_ids[count.index]
  port             = 3000
}

# Backend Target Group Attachment
resource "aws_lb_target_group_attachment" "backend" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = var.instance_ids[count.index]
  port             = 8000
}

# Attach DR RDS to Target Group
# Removed incorrect target group reference
