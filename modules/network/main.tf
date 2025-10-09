variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "Optional VPC ID to use; if empty, creates a temporary VPC"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for created VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "auto_cleanup" {
  description = "Whether to allow destroying the created VPC"
  type        = bool
  default     = true
}

# Check if default VPC exists
data "aws_vpcs" "default_check" {
  filter {
    name   = "is-default"
    values = ["true"]
  }
}

# Lookup by provided VPC ID when given
data "aws_vpc" "by_id" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  use_existing_vpc = var.vpc_id != ""
  has_default_vpc  = length(data.aws_vpcs.default_check.ids) > 0
  create_vpc       = !local.use_existing_vpc && !local.has_default_vpc
}

# Create VPC if needed
resource "aws_vpc" "temp" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-temp-vpc"
    Environment = var.environment
    Temporary   = "true"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "temp" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.temp[0].id

  tags = {
    Name        = "${var.environment}-temp-igw"
    Environment = var.environment
    Temporary   = "true"
  }
}

# Create public subnet
resource "aws_subnet" "temp" {
  count                   = local.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.temp[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-temp-subnet"
    Environment = var.environment
    Temporary   = "true"
  }
}

# Create route table
resource "aws_route_table" "temp" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.temp[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.temp[0].id
  }

  tags = {
    Name        = "${var.environment}-temp-rt"
    Environment = var.environment
    Temporary   = "true"
  }
}

# Associate route table
resource "aws_route_table_association" "temp" {
  count          = local.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.temp[0].id
  route_table_id = aws_route_table.temp[0].id
}

# Get subnets from existing VPC
data "aws_subnets" "existing" {
  count = !local.create_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = local.use_existing_vpc ? [data.aws_vpc.by_id[0].id] : data.aws_vpcs.default_check.ids
  }
}

# Select subnet from existing VPC
data "aws_subnet" "existing" {
  count = !local.create_vpc ? 1 : 0
  id    = data.aws_subnets.existing[0].ids[0]
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = local.create_vpc ? aws_vpc.temp[0].id : (local.use_existing_vpc ? data.aws_vpc.by_id[0].id : data.aws_vpcs.default_check.ids[0])
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = local.create_vpc ? aws_subnet.temp[0].id : data.aws_subnet.existing[0].id
}

output "vpc_created" {
  description = "Whether a temporary VPC was created"
  value       = local.create_vpc
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = local.create_vpc ? aws_vpc.temp[0].cidr_block : null
}
