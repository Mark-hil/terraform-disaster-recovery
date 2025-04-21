# Random password for RDS master user
resource "random_password" "master_password" {
  length  = 16
  special = true
  # Exclude characters that might cause issues
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS Subnet Group
resource "aws_db_subnet_group" "primary" {
  name       = "${var.environment}-${var.database_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

# RDS Parameter Group
resource "aws_db_parameter_group" "primary" {
  name        = "${var.environment}-primary-db-params"
  family      = var.parameter_group_family
  description = "Parameter group for primary RDS instance"

  parameter {
    name  = "max_connections"
    value = "1000"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.database_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Primary RDS Instance
resource "aws_db_instance" "primary" {
  identifier           = lower("${var.environment}-${var.database_name}")
  allocated_storage    = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  db_name             = var.database_name
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = true
  deletion_protection = false

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.primary.name
  parameter_group_name   = aws_db_parameter_group.primary.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  monitoring_interval = 60
  monitoring_role_arn = var.monitoring_role_arn

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
}

# DR Region Read Replica
resource "aws_db_instance" "dr_replica" {
  provider = aws.dr_region

  identifier           = lower("${var.environment}-${var.database_name}-dr-replica")
  instance_class      = "db.t3.micro"
  replicate_source_db = aws_db_instance.primary.arn
  skip_final_snapshot = true

  backup_retention_period = 0
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  monitoring_interval = 60
  monitoring_role_arn = var.monitoring_role_arn

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  depends_on = [aws_db_instance.primary]
}