variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to retain"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

