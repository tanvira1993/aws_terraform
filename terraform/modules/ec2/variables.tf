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

variable "private_subnet_id" {
  description = "Private subnet ID for EC2 instance"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID of EC2 security group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "clickhouse_data_volume_size" {
  description = "ClickHouse data volume size in GB"
  type        = number
}

variable "jenkins_data_volume_size" {
  description = "Jenkins data volume size in GB"
  type        = number
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager Session Manager"
  type        = bool
}

variable "iam_instance_profile" {
  description = "Name of IAM instance profile"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster for kubectl configuration"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "Endpoint of EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

