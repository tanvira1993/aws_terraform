# ============================================================================
# General Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "trading-app"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "trading-app"
    Environment = "production"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

# ============================================================================
# Networking Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []  # Will use first 2 AZs in region if empty
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost optimization)"
  type        = bool
  default     = true
}

# ============================================================================
# EKS Configuration
# ============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS worker nodes"
  type        = list(string)
  default     = ["m5.large"]
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 4
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for EKS worker nodes"
  type        = number
  default     = 50
}

variable "enable_eks_spot_instances" {
  description = "Enable Spot instances for additional EKS nodes"
  type        = bool
  default     = true
}

# ============================================================================
# RDS Configuration
# ============================================================================

variable "rds_instance_class" {
  description = "Instance class for RDS PostgreSQL"
  type        = string
  default     = "db.m5.large"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.5"  # Updated to valid version
}

variable "rds_database_name" {
  description = "Name of the default database"
  type        = string
  default     = "mydb"
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy for connection pooling"
  type        = bool
  default     = true
}

variable "rds_proxy_max_connections" {
  description = "Maximum connections for RDS Proxy"
  type        = number
  default     = 200
}

# ============================================================================
# ElastiCache Redis Configuration
# ============================================================================

variable "redis_node_type" {
  description = "Node type for ElastiCache Redis"
  type        = string
  default     = "cache.t3.small"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes (1 for single node)"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 3
}

# ============================================================================
# Amazon MQ (RabbitMQ) Configuration
# ============================================================================

variable "mq_instance_type" {
  description = "Instance type for Amazon MQ"
  type        = string
  default     = "mq.t3.micro"
}

variable "mq_engine_version" {
  description = "RabbitMQ engine version"
  type        = string
  default     = "3.11.20"
}

variable "mq_deployment_mode" {
  description = "Deployment mode (SINGLE_INSTANCE or CLUSTER_MULTI_AZ)"
  type        = string
  default     = "SINGLE_INSTANCE"
}

variable "mq_admin_username" {
  description = "Admin username for RabbitMQ"
  type        = string
  default     = "admin"
}

# ============================================================================
# EC2 Configuration (ClickHouse + Jenkins)
# ============================================================================

variable "ec2_instance_type" {
  description = "Instance type for EC2 (ClickHouse + Jenkins)"
  type        = string
  default     = "m5.large"
}

variable "ec2_root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "clickhouse_data_volume_size" {
  description = "EBS volume size for ClickHouse data"
  type        = number
  default     = 100
}

variable "jenkins_data_volume_size" {
  description = "EBS volume size for Jenkins data"
  type        = number
  default     = 50
}

variable "ec2_enable_ssm" {
  description = "Enable AWS Systems Manager Session Manager"
  type        = bool
  default     = true
}

# ============================================================================
# Load Balancer Configuration
# ============================================================================

variable "alb_enable_https" {
  description = "Enable HTTPS on ALB"
  type        = bool
  default     = false  # Set to true if you have ACM certificate
}

variable "alb_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for ALB (optional)"
  type        = string
  default     = ""
}

# ============================================================================
# S3 Configuration
# ============================================================================

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "trading-app"
}

variable "s3_lifecycle_logs_expiration_days" {
  description = "Days before logs are deleted"
  type        = number
  default     = 7
}

variable "s3_lifecycle_clickhouse_backup_expiration_days" {
  description = "Days before ClickHouse backups are deleted"
  type        = number
  default     = 15
}

# ============================================================================
# ECR Configuration
# ============================================================================

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "api-server",
    "worker",
    "frontend"
  ]
}

variable "ecr_image_retention_count" {
  description = "Number of images to retain per repository"
  type        = number
  default     = 10
}

# ============================================================================
# CloudWatch Configuration
# ============================================================================

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ============================================================================
# Secrets Manager Configuration
# ============================================================================

variable "secrets_recovery_window_days" {
  description = "Recovery window for deleted secrets"
  type        = number
  default     = 7
}

# ============================================================================
# Cost Optimization
# ============================================================================

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_s3_vpc_endpoint" {
  description = "Enable S3 VPC Gateway Endpoint (free, saves NAT costs)"
  type        = bool
  default     = true
}

