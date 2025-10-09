variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Security group for Kafka
resource "aws_security_group" "kafka_sg" {
  name_prefix = "kafka-${var.environment}-sg-"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kafka broker
  ingress {
    description = "Kafka broker"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Zookeeper
  ingress {
    description = "Zookeeper"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "kafka-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_iam_role" "kafka_role" {
  name = "kafka-dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kafka_role_policy" {
  role       = aws_iam_role.kafka_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "kafka_profile" {
  name = "kafka-dev-profile"
  role = aws_iam_role.kafka_role.name
}

# Outputs
output "kafka_security_group_id" {
  description = "Kafka security group ID"
  value       = aws_security_group.kafka_sg.id
}

output "kafka_instance_profile_name" {
  description = "Kafka IAM instance profile name"
  value       = aws_iam_instance_profile.kafka_profile.name
}

output "spring_boot_security_group_id" {
  description = "Security group ID for Spring Boot instances"
  value       = aws_security_group.kafka_sg.id
}

output "spring_boot_instance_profile_name" {
  description = "IAM instance profile name for Spring Boot instances"
  value       = aws_iam_instance_profile.kafka_profile.name
}

output "springboot_sg_id" {
  description = "Spring Boot Security Group ID"
  value       = aws_security_group.spring_boot_sg.id
}

output "springboot_instance_profile_name" {
  description = "Spring Boot IAM instance profile name"
  value       = aws_iam_instance_profile.spring_boot_profile.name
}
