# IAM role for Lambda function
resource "aws_iam_role" "lambda" {
  name = "${var.environment}-${var.project_name}-failover-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda" {
  name = "${var.environment}-${var.project_name}-failover-lambda"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:PromoteReadReplica",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "sns:Publish"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# Create Lambda function
resource "aws_lambda_function" "failover" {
  filename         = "${path.module}/function.zip"
  function_name    = "${var.environment}-${var.project_name}-failover"
  role            = aws_iam_role.lambda.arn
  handler         = "index.handler"
  runtime         = "nodejs16.x"
  timeout         = 300
  memory_size     = 128

  environment {
    variables = {
      PRIMARY_INSTANCE_ID     = var.primary_instance_id
      DR_INSTANCE_ID         = var.dr_instance_id
      PRIMARY_RDS_ARN        = var.primary_rds_arn
      DR_RDS_ARN            = var.dr_rds_arn
      PRIMARY_TARGET_GROUP_ARN = var.primary_target_group_arn
      DR_TARGET_GROUP_ARN    = var.dr_target_group_arn
      SNS_TOPIC_ARN         = var.sns_topic_arn
    }
  }

  tags = var.tags
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.failover.function_name}"
  retention_in_days = 14

  tags = var.tags
}

# Create Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/function.zip"
  source {
    content = <<EOF
exports.handler = async (event) => {
  const AWS = require('aws-sdk');
  const ec2 = new AWS.EC2();
  const rds = new AWS.RDS();
  const elbv2 = new AWS.ELBv2();
  const sns = new AWS.SNS();

  try {
    // Stop primary EC2 instance
    await ec2.stopInstances({
      InstanceIds: [process.env.PRIMARY_INSTANCE_ID]
    }).promise();

    // Start DR EC2 instance
    await ec2.startInstances({
      InstanceIds: [process.env.DR_INSTANCE_ID]
    }).promise();

    // Promote DR RDS instance
    await rds.promoteReadReplica({
      DBInstanceIdentifier: process.env.DR_RDS_ARN.split(':')[6]
    }).promise();

    // Wait for instance to be available
    await new Promise(resolve => setTimeout(resolve, 60000));

    // Deregister primary instance from target group
    await elbv2.deregisterTargets({
      TargetGroupArn: process.env.PRIMARY_TARGET_GROUP_ARN,
      Targets: [{ Id: process.env.PRIMARY_INSTANCE_ID }]
    }).promise();

    // Register DR instance with target group
    await elbv2.registerTargets({
      TargetGroupArn: process.env.DR_TARGET_GROUP_ARN,
      Targets: [{ Id: process.env.DR_INSTANCE_ID }]
    }).promise();

    // Send notification
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: 'DR Failover Complete',
      Message: 'Successfully failed over to DR environment'
    }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify('Failover completed successfully')
    };
  } catch (error) {
    console.error('Error:', error);
    
    // Send failure notification
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Subject: 'DR Failover Failed',
      Message: 'Failover failed: ' + error.message
    }).promise();

    throw error;
  }
};
EOF
    filename = "index.js"
  }
}
