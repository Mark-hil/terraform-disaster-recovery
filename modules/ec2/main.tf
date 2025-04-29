# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get the latest DR AMI ID from SSM Parameter Store if it exists
data "aws_ssm_parameter" "dr_ami" {
  count           = var.dr_ami_parameter != "" ? 1 : 0
  name            = var.dr_ami_parameter
  with_decryption = true
}

# EC2 Instance Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# EC2 Instances
resource "aws_instance" "app_instances" {
  count                  = var.instance_count

  ami           = var.dr_ami_parameter != "" ? try(data.aws_ssm_parameter.dr_ami[0].value, data.aws_ami.amazon_linux_2.id) : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    environment    = var.environment
    project_name   = var.project_name
    DB_HOST        = var.DB_HOST
    DB_NAME        = var.DB_NAME
    DB_USER        = var.DB_USER
    DB_PASSWORD    = var.DB_PASSWORD
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp2"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-app-instance-${count.index + 1}"
    Environment = var.environment
    AutoStop    = var.instance_state == "stopped" ? "true" : "false"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      user_data,
      user_data_base64
    ]
  }
}

# Handle instance state
resource "null_resource" "instance_state" {
  count = var.instance_state == "stopped" ? var.instance_count : 0

  triggers = {
    instance_id = aws_instance.app_instances[count.index].id
  }

  provisioner "local-exec" {
    command = "aws configure set region ${data.aws_region.current.name} && aws ec2 stop-instances --instance-ids ${aws_instance.app_instances[count.index].id}"
  }

  depends_on = [aws_instance.app_instances]
}

# Get current region
data "aws_region" "current" {}