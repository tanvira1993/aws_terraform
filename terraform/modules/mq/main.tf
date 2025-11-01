# ============================================================================
# Random Password for RabbitMQ
# ============================================================================

resource "random_password" "rabbitmq" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ============================================================================
# Secrets Manager Secret for RabbitMQ Credentials
# ============================================================================

resource "aws_secretsmanager_secret" "rabbitmq" {
  name                    = "${var.project_name}-${var.environment}-rabbitmq-credentials"
  description             = "RabbitMQ admin credentials"
  recovery_window_in_days = var.secrets_recovery_window

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    username = var.admin_username
    password = random_password.rabbitmq.result
  })
}

# ============================================================================
# Amazon MQ (RabbitMQ) Broker
# ============================================================================

resource "aws_mq_broker" "rabbitmq" {
  broker_name        = "${var.project_name}-${var.environment}-rabbitmq"
  engine_type        = "RabbitMQ"
  engine_version     = var.engine_version
  host_instance_type = var.instance_type
  deployment_mode    = var.deployment_mode

  security_groups = [var.rabbitmq_security_group_id]
  subnet_ids      = var.deployment_mode == "SINGLE_INSTANCE" ? [var.private_subnet_ids[0]] : var.private_subnet_ids

  publicly_accessible = false

  user {
    username = var.admin_username
    password = random_password.rabbitmq.result
  }

  logs {
    general = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rabbitmq"
    }
  )
}

