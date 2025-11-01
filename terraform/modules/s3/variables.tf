variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for bucket name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs"
  type        = list(string)
}

variable "enable_vpc_endpoint" {
  description = "Enable S3 VPC Gateway Endpoint"
  type        = bool
}

variable "lifecycle_logs_expiration_days" {
  description = "Days before logs are deleted"
  type        = number
}

variable "lifecycle_clickhouse_backup_expiration_days" {
  description = "Days before ClickHouse backups are deleted"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

