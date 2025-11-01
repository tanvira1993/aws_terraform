# ============================================================================
# Data Sources
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  
  common_tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = var.environment
      Project     = var.project_name
    }
  )

  account_id = data.aws_caller_identity.current.account_id
}

# ============================================================================
# Networking Module
# ============================================================================

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.common_tags
}

# ============================================================================
# S3 Module (with VPC Gateway Endpoint)
# ============================================================================

module "s3" {
  source = "./modules/s3"

  project_name                             = var.project_name
  environment                              = var.environment
  bucket_prefix                            = var.s3_bucket_prefix
  vpc_id                                   = module.networking.vpc_id
  private_route_table_ids                  = module.networking.private_route_table_ids
  enable_vpc_endpoint                      = var.enable_s3_vpc_endpoint
  lifecycle_logs_expiration_days           = var.s3_lifecycle_logs_expiration_days
  lifecycle_clickhouse_backup_expiration_days = var.s3_lifecycle_clickhouse_backup_expiration_days
  tags                                     = local.common_tags
}

# ============================================================================
# Security Groups Module
# ============================================================================

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
  tags         = local.common_tags
}

# ============================================================================
# IAM Module
# ============================================================================

module "iam" {
  source = "./modules/iam"

  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_arn  = module.s3.bucket_arn
  ecr_arns       = [for repo in module.ecr : repo.repository_arn]
  tags           = local.common_tags
}

# ============================================================================
# ECR Module
# ============================================================================

module "ecr" {
  source   = "./modules/ecr"
  for_each = toset(var.ecr_repositories)

  project_name         = var.project_name
  environment          = var.environment
  repository_name      = each.value
  image_retention_count = var.ecr_image_retention_count
  tags                 = local.common_tags
}

# ============================================================================
# RDS Module (PostgreSQL + RDS Proxy)
# ============================================================================

module "rds" {
  source = "./modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  rds_security_group_id      = module.security_groups.rds_security_group_id
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  engine_version             = var.rds_engine_version
  database_name              = var.rds_database_name
  master_username            = var.rds_master_username
  backup_retention_period    = var.rds_backup_retention_period
  enable_rds_proxy           = var.enable_rds_proxy
  rds_proxy_max_connections  = var.rds_proxy_max_connections
  rds_proxy_role_arn         = module.iam.rds_proxy_role_arn
  secrets_recovery_window    = var.secrets_recovery_window_days
  tags                       = local.common_tags
}

# ============================================================================
# ElastiCache Redis Module
# ============================================================================

module "elasticache" {
  source = "./modules/elasticache"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  redis_security_group_id    = module.security_groups.redis_security_group_id
  node_type                  = var.redis_node_type
  num_cache_nodes            = var.redis_num_cache_nodes
  engine_version             = var.redis_engine_version
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  tags                       = local.common_tags
}

# ============================================================================
# Amazon MQ (RabbitMQ) Module
# ============================================================================

module "mq" {
  source = "./modules/mq"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  rabbitmq_security_group_id = module.security_groups.rabbitmq_security_group_id
  instance_type              = var.mq_instance_type
  engine_version             = var.mq_engine_version
  deployment_mode            = var.mq_deployment_mode
  admin_username             = var.mq_admin_username
  secrets_recovery_window    = var.secrets_recovery_window_days
  tags                       = local.common_tags
}

# ============================================================================
# EKS Module
# ============================================================================

module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  cluster_version        = var.eks_cluster_version
  node_instance_types    = var.eks_node_instance_types
  node_min_size          = var.eks_node_min_size
  node_max_size          = var.eks_node_max_size
  node_desired_size      = var.eks_node_desired_size
  node_disk_size         = var.eks_node_disk_size
  enable_spot_instances  = var.enable_eks_spot_instances
  eks_security_group_id  = module.security_groups.eks_cluster_security_group_id
  node_security_group_id = module.security_groups.eks_node_security_group_id
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.eks_node_role_arn
  tags                   = local.common_tags
}

# ============================================================================
# EC2 Module (ClickHouse + Jenkins)
# ============================================================================

module "ec2" {
  source = "./modules/ec2"

  project_name                = var.project_name
  environment                 = var.environment
  vpc_id                      = module.networking.vpc_id
  private_subnet_id           = module.networking.private_subnet_ids[0]
  ec2_security_group_id       = module.security_groups.ec2_security_group_id
  instance_type               = var.ec2_instance_type
  root_volume_size            = var.ec2_root_volume_size
  clickhouse_data_volume_size = var.clickhouse_data_volume_size
  jenkins_data_volume_size    = var.jenkins_data_volume_size
  enable_ssm                  = var.ec2_enable_ssm
  iam_instance_profile        = module.iam.ec2_instance_profile_name
  eks_cluster_name            = module.eks.cluster_name
  eks_cluster_endpoint        = module.eks.cluster_endpoint
  tags                        = local.common_tags
}

# ============================================================================
# Application Load Balancer Module
# ============================================================================

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  enable_https          = var.alb_enable_https
  certificate_arn       = var.alb_certificate_arn
  domain_name           = var.domain_name
  jenkins_instance_id   = module.ec2.instance_id
  jenkins_private_ip    = module.ec2.private_ip
  tags                  = local.common_tags
}

# ============================================================================
# CloudWatch Module - REMOVED (cost optimization)
# ============================================================================
# Using in-cluster monitoring tools (Prometheus, Grafana, Loki) instead
# Saves ~$8/month

