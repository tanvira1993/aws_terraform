output "broker_id" {
  description = "ID of the RabbitMQ broker"
  value       = aws_mq_broker.rabbitmq.id
}

output "broker_arn" {
  description = "ARN of the RabbitMQ broker"
  value       = aws_mq_broker.rabbitmq.arn
}

output "broker_endpoint" {
  description = "Endpoint of the RabbitMQ broker (AMQP)"
  value       = try(aws_mq_broker.rabbitmq.instances[0].endpoints[0], "")
}

output "console_url" {
  description = "URL of the RabbitMQ management console"
  value       = try(aws_mq_broker.rabbitmq.instances[0].console_url, "")
}

output "admin_username" {
  description = "Admin username for RabbitMQ"
  value       = var.admin_username
}

output "admin_password" {
  description = "Admin password for RabbitMQ"
  value       = random_password.rabbitmq.result
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of Secrets Manager secret"
  value       = aws_secretsmanager_secret.rabbitmq.arn
}

