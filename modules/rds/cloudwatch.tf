# CloudWatch Alarms for RDS

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.environment}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions       = []
  ok_actions          = []

  dimensions = {
    DBInstanceIdentifier = var.create_replica ? aws_db_instance.dr_replica[0].id : aws_db_instance.primary[0].id
  }

  tags = {
    Name = "${var.environment}-rds-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  alarm_name          = "${var.environment}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000000000"  # 5GB in bytes
  alarm_description   = "RDS free storage space is too low"
  alarm_actions       = []
  ok_actions          = []

  dimensions = {
    DBInstanceIdentifier = var.create_replica ? aws_db_instance.dr_replica[0].id : aws_db_instance.primary[0].id
  }

  tags = {
    Name = "${var.environment}-rds-storage-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  alarm_name          = "${var.environment}-rds-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000"  # 1GB in bytes
  alarm_description   = "RDS freeable memory is too low"
  alarm_actions       = []
  ok_actions          = []

  dimensions = {
    DBInstanceIdentifier = var.create_replica ? aws_db_instance.dr_replica[0].id : aws_db_instance.primary[0].id
  }

  tags = {
    Name = "${var.environment}-rds-memory-alarm"
  }
}
