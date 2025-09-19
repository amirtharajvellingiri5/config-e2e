

variable "kafka_image_uri" {
  description = "Docker image URI for Kafka (Docker Hub)"
  type        = string
  default     = "vishnukanthmca/kafka:latest"
}

variable "springboot_instance_type" {
  default = "t3.small"
}


variable "app_image_uri" {
  description = "Docker image URI"
  type        = string
  default     = "vishnukanthmca/springboot-app:latest"
}
