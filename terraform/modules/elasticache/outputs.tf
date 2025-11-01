output "cluster_id" {
  description = "ID of the Redis cluster"
  value       = aws_elasticache_cluster.redis.id
}

output "cluster_endpoint" {
  description = "Endpoint of the Redis cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "cluster_port" {
  description = "Port of the Redis cluster"
  value       = aws_elasticache_cluster.redis.port
}

output "cluster_arn" {
  description = "ARN of the Redis cluster"
  value       = aws_elasticache_cluster.redis.arn
}

