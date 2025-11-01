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

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of ALB security group"
  type        = string
}

variable "enable_https" {
  description = "Enable HTTPS"
  type        = bool
}

variable "certificate_arn" {
  description = "ARN of ACM certificate"
  type        = string
}

variable "domain_name" {
  description = "Domain name for routing"
  type        = string
}

variable "jenkins_instance_id" {
  description = "ID of Jenkins EC2 instance"
  type        = string
}

variable "jenkins_private_ip" {
  description = "Private IP of Jenkins instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

