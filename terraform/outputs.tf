# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# ============================================================================
# EKS Outputs
# ============================================================================

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data for EKS cluster"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "eks_configure_kubectl" {
  description = "Command to configure kubectl for EKS cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# ============================================================================
# RDS Outputs
# ============================================================================

output "rds_endpoint" {
  description = "Endpoint of RDS PostgreSQL instance"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "Port of RDS PostgreSQL instance"
  value       = module.rds.db_port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.rds.db_name
}

output "rds_master_username" {
  description = "Master username for RDS"
  value       = module.rds.db_username
}

output "rds_password" {
  description = "Master password for RDS (stored in Secrets Manager)"
  value       = module.rds.db_password
  sensitive   = true
}

output "rds_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS credentials"
  value       = module.rds.secret_arn
}

output "rds_proxy_endpoint" {
  description = "Endpoint of RDS Proxy (use this for connections)"
  value       = module.rds.proxy_endpoint
}

output "rds_connection_string" {
  description = "Connection string for PostgreSQL via RDS Proxy"
  value       = "postgresql://${module.rds.db_username}:${module.rds.db_password}@${module.rds.proxy_endpoint}:${module.rds.db_port}/${module.rds.db_name}"
  sensitive   = true
}

# ============================================================================
# Redis Outputs
# ============================================================================

output "redis_endpoint" {
  description = "Endpoint of ElastiCache Redis cluster"
  value       = module.elasticache.cluster_endpoint
}

output "redis_port" {
  description = "Port of Redis cluster"
  value       = module.elasticache.cluster_port
}

output "redis_cluster_id" {
  description = "ID of Redis cluster"
  value       = module.elasticache.cluster_id
}

output "redis_connection_string" {
  description = "Connection string for Redis"
  value       = "redis://${module.elasticache.cluster_endpoint}:${module.elasticache.cluster_port}"
}

# ============================================================================
# RabbitMQ Outputs
# ============================================================================

output "rabbitmq_endpoint" {
  description = "Endpoint of Amazon MQ RabbitMQ broker"
  value       = module.mq.broker_endpoint
}

output "rabbitmq_console_url" {
  description = "URL of RabbitMQ management console"
  value       = module.mq.console_url
}

output "rabbitmq_admin_username" {
  description = "Admin username for RabbitMQ"
  value       = module.mq.admin_username
}

output "rabbitmq_admin_password" {
  description = "Admin password for RabbitMQ (stored in Secrets Manager)"
  value       = module.mq.admin_password
  sensitive   = true
}

output "rabbitmq_secret_arn" {
  description = "ARN of Secrets Manager secret containing RabbitMQ credentials"
  value       = module.mq.secret_arn
}

output "rabbitmq_amqp_connection_string" {
  description = "AMQP connection string for RabbitMQ"
  value       = "amqps://${module.mq.admin_username}:${module.mq.admin_password}@${module.mq.broker_endpoint}:5671"
  sensitive   = true
}

# ============================================================================
# EC2 (ClickHouse + Jenkins) Outputs
# ============================================================================

output "clickhouse_instance_id" {
  description = "ID of EC2 instance running ClickHouse + Jenkins"
  value       = module.ec2.instance_id
}

output "clickhouse_private_ip" {
  description = "Private IP of ClickHouse + Jenkins instance"
  value       = module.ec2.private_ip
}

output "clickhouse_http_port" {
  description = "ClickHouse HTTP port"
  value       = "8123"
}

output "clickhouse_native_port" {
  description = "ClickHouse native port"
  value       = "9000"
}

output "clickhouse_connection_string" {
  description = "ClickHouse connection string (HTTP)"
  value       = "http://${module.ec2.private_ip}:8123"
}

output "jenkins_private_url" {
  description = "Jenkins URL (accessible via ALB or port forwarding)"
  value       = "http://${module.ec2.private_ip}:8080"
}

output "ec2_ssm_connect_command" {
  description = "Command to connect to EC2 via AWS Systems Manager"
  value       = "aws ssm start-session --target ${module.ec2.instance_id} --region ${var.aws_region}"
}

# ============================================================================
# ALB Outputs
# ============================================================================

output "alb_dns_name" {
  description = "DNS name of Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "jenkins_url" {
  description = "Public URL for Jenkins (via ALB)"
  value       = var.domain_name != "" ? "https://jenkins.${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

output "api_url" {
  description = "Public URL for API (via ALB)"
  value       = var.domain_name != "" ? "https://api.${var.domain_name}" : "http://${module.alb.alb_dns_name}"
}

# ============================================================================
# S3 Outputs
# ============================================================================

output "s3_bucket_name" {
  description = "Name of S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of S3 bucket"
  value       = module.s3.bucket_arn
}

output "s3_bucket_region" {
  description = "Region of S3 bucket"
  value       = module.s3.bucket_region
}

# ============================================================================
# ECR Outputs
# ============================================================================

output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = { for k, v in module.ecr : k => v.repository_url }
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ============================================================================
# IAM Outputs
# ============================================================================

output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of EKS node IAM role"
  value       = module.iam.eks_node_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile"
  value       = module.iam.ec2_instance_profile_name
}

# ============================================================================
# Summary Output
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
    vpc_id       = module.networking.vpc_id
    eks_cluster  = module.eks.cluster_name
    rds_endpoint = module.rds.proxy_endpoint
    redis_endpoint = module.elasticache.cluster_endpoint
    rabbitmq_endpoint = module.mq.broker_endpoint
    alb_dns = module.alb.alb_dns_name
    s3_bucket = module.s3.bucket_name
  }
}

# ============================================================================
# Quick Access Credentials (Use with caution - contains sensitive data)
# ============================================================================

output "all_credentials" {
  description = "All credentials in one place (SENSITIVE - use terraform output -json > credentials.json)"
  value = {
    rds = {
      endpoint = module.rds.proxy_endpoint
      port     = module.rds.db_port
      database = module.rds.db_name
      username = module.rds.db_username
      password = module.rds.db_password
      connection_string = "postgresql://${module.rds.db_username}:${module.rds.db_password}@${module.rds.proxy_endpoint}:${module.rds.db_port}/${module.rds.db_name}"
    }
    redis = {
      endpoint = module.elasticache.cluster_endpoint
      port     = module.elasticache.cluster_port
      connection_string = "redis://${module.elasticache.cluster_endpoint}:${module.elasticache.cluster_port}"
    }
    rabbitmq = {
      endpoint = module.mq.broker_endpoint
      console_url = module.mq.console_url
      username = module.mq.admin_username
      password = module.mq.admin_password
      amqp_url = "amqps://${module.mq.admin_username}:${module.mq.admin_password}@${module.mq.broker_endpoint}:5671"
    }
    clickhouse = {
      private_ip = module.ec2.private_ip
      http_port = "8123"
      native_port = "9000"
      http_url = "http://${module.ec2.private_ip}:8123"
    }
    jenkins = {
      private_url = "http://${module.ec2.private_ip}:8080"
      public_url = var.domain_name != "" ? "https://jenkins.${var.domain_name}" : "http://${module.alb.alb_dns_name}"
    }
    eks = {
      cluster_name = module.eks.cluster_name
      endpoint = module.eks.cluster_endpoint
      configure_command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
    }
  }
  sensitive = true
}

