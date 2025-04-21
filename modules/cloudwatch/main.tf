# CloudWatch Module for DR Monitoring

# SNS Topic for Alerts
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.environment}-${var.region}-dr-alerts"
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "dr_alerts" {
  arn = aws_sns_topic.dr_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.dr_alerts.arn
      }
    ]
  })
}

# EC2 CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.environment}-${var.region}-ec2-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    InstanceId = "*"
  }
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-${var.region}-rds-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors RDS CPU utilization"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "*"
  }
}

# RDS Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.environment}-${var.region}-rds-storage-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "5000000000" # 5GB
  alarm_description  = "This metric monitors RDS free storage space"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "*"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "dr_dashboard" {
  dashboard_name = "${var.environment}-${var.region}-dr-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "*"],
            [".", "NetworkIn", ".", "*"],
            [".", "NetworkOut", ".", "*"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "*"],
            [".", "FreeStorageSpace", ".", "*"],
            [".", "ReadIOPS", ".", "*"],
            [".", "WriteIOPS", ".", "*"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "RDS Metrics"
        }
      }
    ]
  })
}