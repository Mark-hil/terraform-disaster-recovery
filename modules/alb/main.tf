# Application Load Balancer Module

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-${var.name}-alb-sg"
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
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend API access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  enable_http2               = true

  tags = merge(var.tags, {
    Name = var.name
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
    matcher             = "200"
    path                = "/"
    port                = "3000"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

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
    path                = "/admin/"
    port                = "8000"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

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
