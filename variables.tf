
variable "key_name" {
  type        = string
  description = "The name of the EC2 Key Pair to use for SSH access"
}


variable "kafka_image_uri" {
  description = "Docker image URI for Kafka (Docker Hub)"
  type        = string
  default     = "vishnukanthmca/kafka:latest"
}

variable "dockerhub_user" {
  description = "DockerHub username"
  type        = string
}

variable "dockerhub_password" {
  description = "DockerHub password/token"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Kafka is deployed"
  type        = string
}
