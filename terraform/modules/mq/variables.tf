variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rabbitmq_security_group_id" {
  description = "ID of RabbitMQ security group"
  type        = string
}

variable "instance_type" {
  description = "Instance type for RabbitMQ"
  type        = string
}

variable "engine_version" {
  description = "RabbitMQ engine version"
  type        = string
}

variable "deployment_mode" {
  description = "Deployment mode (SINGLE_INSTANCE or CLUSTER_MULTI_AZ)"
  type        = string
}

variable "admin_username" {
  description = "Admin username for RabbitMQ"
  type        = string
}

variable "secrets_recovery_window" {
  description = "Recovery window for secrets in days"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

