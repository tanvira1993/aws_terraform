output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "jenkins_target_group_arn" {
  description = "ARN of Jenkins target group"
  value       = aws_lb_target_group.jenkins.arn
}

output "eks_target_group_arn" {
  description = "ARN of EKS target group"
  value       = aws_lb_target_group.eks.arn
}

