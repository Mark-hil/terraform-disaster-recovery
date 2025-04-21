# Application Load Balancer Module

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for DR ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Application Load Balancer
resource "aws_lb" "dr" {
  name               = "${var.project_name}-dr-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.subnet_ids

  enable_deletion_protection = true
  enable_http2             = true

  tags = var.tags
}

# Primary Target Group
resource "aws_lb_target_group" "primary" {
  name        = "${var.project_name}-primary-tg"
  port        = 3306
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval           = 30
    protocol           = "TCP"
    timeout            = 10
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# DR Target Group
resource "aws_lb_target_group" "dr" {
  name        = "${var.project_name}-dr-tg"
  port        = 3306
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval           = 30
    protocol           = "TCP"
    timeout            = 10
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# ALB Listener
resource "aws_lb_listener" "dr" {
  load_balancer_arn = aws_lb.dr.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

# Attach Primary RDS to Target Group
resource "aws_lb_target_group_attachment" "primary" {
  target_group_arn = aws_lb_target_group.primary.arn
  target_id        = var.primary_rds_address
  port             = 3306
}

# Attach DR RDS to Target Group
resource "aws_lb_target_group_attachment" "dr" {
  target_group_arn = aws_lb_target_group.dr.arn
  target_id        = var.dr_rds_address
  port             = 3306
}
