##########################
# VARIABLES
##########################
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subnet IDs for EC2 instance (expects a list; the first item will be used)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Kafka instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH (optional)"
  type        = string
}

variable "dockerhub_user" {
  description = "DockerHub username for pulling images"
  type        = string
  default     = "vishnukanthmca"
}

variable "dockerhub_password" {
  description = "DockerHub password / token"
  type        = string
  sensitive   = true
}

##########################
# DATA SOURCE
##########################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

##########################
# ELASTIC IP
##########################
resource "aws_eip" "kafka_eip" {
  domain = "vpc"

  tags = {
    Name        = "kafka-${var.environment}-eip"
    Environment = var.environment
  }
}

##########################
# EC2 INSTANCE
##########################
resource "aws_instance" "kafka" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id[0]
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    kafka_external_ip  = aws_eip.kafka_eip.public_ip
    dockerhub_user     = var.dockerhub_user
    dockerhub_password = var.dockerhub_password
    environment        = var.environment
  })

  tags = {
    Name        = "kafka-${var.environment}-server"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

##########################
# EIP ASSOCIATION
##########################
resource "aws_eip_association" "kafka_eip_assoc" {
  instance_id   = aws_instance.kafka.id
  allocation_id = aws_eip.kafka_eip.id
}

##########################
# OUTPUTS
##########################
output "kafka_public_ip" {
  description = "Public IP of Kafka Server"
  value       = aws_eip.kafka_eip.public_ip
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  value       = "${aws_eip.kafka_eip.public_ip}:9092"
}

output "ssh_command" {
  description = "SSH command to connect Kafka server"
  value       = "ssh -i your-key.pem ec2-user@${aws_eip.kafka_eip.public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.kafka.id
}
