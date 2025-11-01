# ============================================================================
# ALB Security Group
# ============================================================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# EKS Cluster Security Group
# ============================================================================

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_nodes" {
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow worker nodes to communicate with control plane"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_all" {
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# EKS Worker Nodes Security Group
# ============================================================================

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.project_name}-${var.environment}-eks-nodes-sg"
      "kubernetes.io/cluster/${var.project_name}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_self" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow nodes to communicate with each other"
  ip_protocol       = "-1"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_cluster" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow control plane to communicate with nodes"
  ip_protocol       = "-1"
  referenced_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_alb" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow ALB to communicate with pods"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_all" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# RDS Security Group
# ============================================================================

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_eks" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow EKS nodes to access PostgreSQL"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_ec2" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow EC2 (ClickHouse/Jenkins) to access PostgreSQL"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# Redis Security Group
# ============================================================================

resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-${var.environment}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_eks" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow EKS nodes to access Redis"
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_ec2" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow EC2 to access Redis"
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# RabbitMQ Security Group
# ============================================================================

resource "aws_security_group" "rabbitmq" {
  name_prefix = "${var.project_name}-${var.environment}-rabbitmq-"
  description = "Security group for Amazon MQ RabbitMQ"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rabbitmq-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_amqp_eks" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow EKS nodes to access RabbitMQ (AMQP)"
  from_port         = 5672
  to_port           = 5672
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_amqps_eks" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow EKS nodes to access RabbitMQ (AMQPS)"
  from_port         = 5671
  to_port           = 5671
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_console_eks" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow EKS nodes to access RabbitMQ console"
  from_port         = 15672
  to_port           = 15672
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "rabbitmq_ec2" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow EC2 to access RabbitMQ"
  from_port         = 5672
  to_port           = 5672
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id
}

resource "aws_vpc_security_group_egress_rule" "rabbitmq_all" {
  security_group_id = aws_security_group.rabbitmq.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================================
# EC2 Security Group (ClickHouse + Jenkins)
# ============================================================================

resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"
  description = "Security group for EC2 instance (ClickHouse + Jenkins)"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ec2-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ClickHouse HTTP
resource "aws_vpc_security_group_ingress_rule" "ec2_clickhouse_http" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow EKS nodes to access ClickHouse HTTP"
  from_port         = 8123
  to_port           = 8123
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# ClickHouse Native
resource "aws_vpc_security_group_ingress_rule" "ec2_clickhouse_native" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow EKS nodes to access ClickHouse native"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# Jenkins
resource "aws_vpc_security_group_ingress_rule" "ec2_jenkins_alb" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow ALB to access Jenkins"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# Jenkins agent port
resource "aws_vpc_security_group_ingress_rule" "ec2_jenkins_agent" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow EKS nodes (Jenkins agents) to connect to Jenkins master"
  from_port         = 50000
  to_port           = 50000
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

