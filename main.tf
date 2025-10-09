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

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "dockerhub_user" {
  description = "DockerHub username"
  type        = string
}

variable "dockerhub_password" {
  description = "DockerHub password or token"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# -------------------------
# Dynamic VPC and Networking
# -------------------------
resource "aws_vpc" "dynamic_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.dynamic_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.environment}-public-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dynamic_vpc.id
  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dynamic_vpc.id
  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Module
# -------------------------
module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = aws_vpc.dynamic_vpc.id
}

# -------------------------
# Kafka Module
# -------------------------
module "kafka" {
  source                = "./modules/kafka"
  environment           = var.environment
  instance_type         = var.instance_type
  subnet_id             = aws_subnet.public[*].id
  security_group_id     = module.security.kafka_security_group_id
  instance_profile_name = module.security.kafka_instance_profile_name
  key_name              = var.key_name
  dockerhub_user        = var.dockerhub_user
  dockerhub_password    = var.dockerhub_password
  vpc_id                = aws_vpc.dynamic_vpc.id

  depends_on = [
    module.security
  ]
}

module "springboot_security" {
  source      = "./modules/springboot_security"
  environment = var.environment
  vpc_id      = var.vpc_id
}

module "springboot" {
  source                = "./modules/springboot"
  environment           = var.environment
  instance_type         = var.springboot_instance_type
  subnet_id             = module.network.public_subnet_id
  security_group_id     = module.security.springboot_sg_id
  instance_profile_name = module.security.springboot_instance_profile_name
  key_name              = var.key_name
  app_image_uri         = var.app_image_uri
}


module "network" {
  source      = "./modules/network"
  environment = var.environment
  # any other inputs your network module requires
}


# -------------------------
# Outputs
# -------------------------
output "vpc_id" {
  description = "ID of the dynamically created VPC"
  value       = aws_vpc.dynamic_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

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
