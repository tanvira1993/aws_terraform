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

variable "rds_security_group_id" {
  description = "ID of RDS security group"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy"
  type        = bool
}

variable "rds_proxy_max_connections" {
  description = "Maximum connections for RDS Proxy"
  type        = number
}

variable "rds_proxy_role_arn" {
  description = "ARN of IAM role for RDS Proxy"
  type        = string
  default     = ""
}

variable "secrets_recovery_window" {
  description = "Recovery window for secrets in days"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

