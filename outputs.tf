

output "springboot_public_ip" {
  description = "Public IP of Spring Boot server"
  value       = module.springboot.springboot_public_ip
}

output "springboot_url" {
  description = "Spring Boot app URL"
  value       = module.springboot.springboot_url
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}
