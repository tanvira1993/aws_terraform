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

variable "redis_security_group_id" {
  description = "ID of Redis security group"
  type        = string
}

variable "node_type" {
  description = "Node type for Redis"
  type        = string
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

