output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "clickhouse_data_volume_id" {
  description = "ID of ClickHouse data EBS volume"
  value       = aws_ebs_volume.clickhouse_data.id
}

output "jenkins_data_volume_id" {
  description = "ID of Jenkins data EBS volume"
  value       = aws_ebs_volume.jenkins_data.id
}

