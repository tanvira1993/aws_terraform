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

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_disk_size" {
  description = "Disk size for worker nodes in GB"
  type        = number
}

variable "enable_spot_instances" {
  description = "Enable Spot instances for additional nodes"
  type        = bool
}

variable "eks_security_group_id" {
  description = "ID of EKS cluster security group"
  type        = string
}

variable "node_security_group_id" {
  description = "ID of EKS node security group"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of EKS cluster IAM role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of EKS node IAM role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

