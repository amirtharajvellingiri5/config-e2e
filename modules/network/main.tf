variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "Optional VPC ID to use; if empty the module will attempt to use the default VPC"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Optional specific subnet ID to use; if empty, uses first available subnet in VPC"
  type        = string
  default     = ""
}

# Lookup by provided VPC ID when given
data "aws_vpc" "by_id" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

# Fallback to default VPC only when no vpc_id is provided
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

locals {
  vpc_id = var.vpc_id != "" ? data.aws_vpc.by_id[0].id : data.aws_vpc.default[0].id
}

# Get all subnets in the VPC
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Lookup specific subnet if provided
data "aws_subnet" "by_id" {
  count = var.subnet_id != "" ? 1 : 0
  id    = var.subnet_id
}

# Use first available subnet as fallback
data "aws_subnet" "selected" {
  count = var.subnet_id == "" ? 1 : 0
  id    = data.aws_subnets.available.ids[0]
}

locals {
  subnet_id = var.subnet_id != "" ? data.aws_subnet.by_id[0].id : data.aws_subnet.selected[0].id
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "public_subnet_id" {
  description = "Selected subnet ID"
  value       = local.subnet_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.vpc_id != "" ? data.aws_vpc.by_id[0].cidr_block : data.aws_vpc.default[0].cidr_block
}

output "available_subnet_ids" {
  description = "All available subnet IDs in the VPC"
  value       = data.aws_subnets.available.ids
}
