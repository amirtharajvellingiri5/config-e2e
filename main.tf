terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# Variables
# -------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for Kafka"
  type        = string
  default     = "t3.small"
}


# -------------------------
# Network Module
# -------------------------
module "network" {
  source      = "./modules/network"
  environment = var.environment
}

# -------------------------
# Security Module
# -------------------------
module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = module.network.vpc_id
}

# -------------------------
# Kafka Module
# -------------------------
module "kafka" {
  source                = "./modules/kafka"
  environment           = var.environment
  instance_type         = var.instance_type
  subnet_id             = module.network.public_subnet_id
  security_group_id     = module.security.kafka_security_group_id
  instance_profile_name = module.security.kafka_instance_profile_name
  key_name              = var.key_name
  dockerhub_user        = var.dockerhub_user
  dockerhub_password    = var.dockerhub_password

  depends_on = [
    module.network,
    module.security
  ]
}


# -------------------------
# Outputs
# -------------------------
output "kafka_public_ip" {
  description = "Public IP of Kafka server"
  value       = module.kafka.kafka_public_ip
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  value       = module.kafka.kafka_bootstrap_servers
}

output "ssh_command" {
  description = "SSH command to connect to Kafka server"
  value       = module.kafka.ssh_command
}
