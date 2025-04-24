# Application Load Balancer Module

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-${var.name}-alb-"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Frontend HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-alb"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-${substr(var.project_name, 0, 15)}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.subnet_ids

  enable_deletion_protection = false
  enable_http2             = true

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-alb"
  })
}

# Frontend Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.environment}-${substr(var.project_name, 0, 15)}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher             = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-tg"
  })
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name     = "${var.environment}-${substr(var.project_name, 0, 15)}-back"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/admin/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.name}-backend-tg"
  })
}

# Frontend Listener (HTTP)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Backend Listener
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
