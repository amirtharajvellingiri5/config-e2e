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
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Spring Boot instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2 instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "app_image_uri" {
  description = "Docker image URI for Spring Boot app (Docker Hub)"
  type        = string
  default     = "vishnukanthmca/springboot-app:latest"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_eip" "springboot_eip" {
  domain = "vpc"

  tags = {
    Name        = "springboot-${var.environment}-eip"
    Environment = var.environment
  }
}

resource "aws_instance" "springboot" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data.sh", {
    app_image_uri = var.app_image_uri
    environment   = var.environment
  })

  tags = {
    Name        = "springboot-${var.environment}-server"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "springboot_eip_assoc" {
  instance_id   = aws_instance.springboot.id
  allocation_id = aws_eip.springboot_eip.id
}

output "springboot_public_ip" {
  description = "Public IP of Spring Boot App Server"
  value       = aws_eip.springboot_eip.public_ip
}

output "springboot_url" {
  description = "Spring Boot App URL"
  value       = "http://${aws_eip.springboot_eip.public_ip}:8080"
}
