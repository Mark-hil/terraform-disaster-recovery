# CloudWatch Module for DR Monitoring

# SNS Topic for Alerts
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.environment}-${var.region}-dr-alerts"
}

# Email subscription for alerts
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = "chillop.learn@gmail.com"
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

# EC2 Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "primary_ec2_status" {
  alarm_name          = "${var.environment}-${var.region}-primary-ec2-status-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Maximum"
  threshold          = "0"
  alarm_description  = "This metric monitors EC2 status checks"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn, var.lambda_function_arn]

  dimensions = {
    InstanceId = var.primary_instance_id
  }
}

# RDS Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "primary_rds_status" {
  alarm_name          = "${var.environment}-${var.region}-primary-rds-status-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/RDS"
  period             = "60"
  statistic          = "Maximum"
  threshold          = "0"
  alarm_description  = "This metric monitors RDS status checks"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn, var.lambda_function_arn]

  dimensions = {
    DBInstanceIdentifier = var.primary_rds_id
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

# EC2 Status Check Alarm - Triggers failover
resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${var.environment}-${var.region}-ec2-status-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"
  period             = "60"  # Check every minute
  statistic          = "Maximum"
  threshold          = "0"
  alarm_description  = "This metric monitors EC2 status checks and triggers DR failover"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn, var.lambda_function_arn]

  dimensions = {
    InstanceId = "*"
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