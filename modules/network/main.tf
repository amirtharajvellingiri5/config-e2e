variable "environment" {
  description = "Environment name"
  type        = string
}

# Get default VPC (simplified approach)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  id = data.aws_subnets.default.ids[0]
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.default.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = data.aws_subnet.default.id
}
