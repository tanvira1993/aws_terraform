# AWS Infrastructure Terraform

Complete AWS infrastructure for production-grade application with EKS, RDS, Redis, RabbitMQ, ClickHouse, and Jenkins.

## 📋 Architecture Overview

This Terraform code deploys:
- **VPC** with public/private subnets across 2 AZs
- **EKS Cluster** with autoscaling node groups (1-4 m5.large nodes)
- **RDS PostgreSQL** (db.m5.large) with RDS Proxy
- **ElastiCache Redis** (cache.t3.small)
- **Amazon MQ RabbitMQ** (mq.t3.micro)
- **EC2** (m5.large) for ClickHouse + Jenkins
- **Application Load Balancer** with SSL/TLS
- **S3** with VPC Gateway Endpoint
- **ECR** repositories for Docker images
- **CloudWatch** monitoring and logging

**Monthly Cost:** ~$456-513/month (based on context.md)

---

## 🚀 Quick Start

### Prerequisites

1. **Install Terraform** (on macOS):
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version  # Should show v1.5.0 or higher
```

2. **Install AWS CLI**:
```bash
brew install awscli

# Configure AWS credentials
aws configure
# Enter: AWS Access Key ID
# Enter: AWS Secret Access Key
# Enter: Default region (e.g., us-east-1)
# Enter: Default output format (json)
```

3. **Install kubectl** (for EKS management):
```bash
brew install kubectl
```

---

## 📁 Project Structure

```
terraform/
├── README.md                    # This file
├── main.tf                      # Root module configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values (credentials, endpoints)
├── versions.tf                  # Provider version constraints
├── backend.tf                   # State backend configuration
│
├── modules/                     # Reusable modules
│   ├── networking/              # VPC, subnets, NAT, IGW
│   ├── eks/                     # EKS cluster and node groups
│   ├── rds/                     # PostgreSQL + RDS Proxy
│   ├── elasticache/             # Redis cluster
│   ├── mq/                      # RabbitMQ broker
│   ├── ec2/                     # ClickHouse + Jenkins instance
│   ├── alb/                     # Application Load Balancer
│   ├── s3/                      # S3 bucket + VPC endpoint
│   ├── ecr/                     # Container registries
│   ├── iam/                     # IAM roles and policies
│   └── security-groups/         # Security group rules
│
├── environments/                # Environment-specific configs
│   ├── dev/
│   │   └── terraform.tfvars
│   └── prod/
│       └── terraform.tfvars
│
└── scripts/                     # Helper scripts
    ├── install-clickhouse.sh
    ├── install-jenkins.sh
    └── configure-eks.sh
```

---

## 🔧 Configuration

### Step 1: Customize Variables

Edit `terraform.tfvars` or create one:

```hcl
# terraform.tfvars
aws_region     = "us-east-1"
project_name   = "trading-app"
environment    = "production"

# Domain (optional - for ALB SSL certificate)
domain_name    = "example.com"  # Leave empty if no domain

# CIDR blocks
vpc_cidr       = "10.0.0.0/16"

# Instance types
eks_node_instance_types = ["m5.large"]
rds_instance_class      = "db.m5.large"
ec2_instance_type       = "m5.large"

# Scaling
eks_node_min_size = 1
eks_node_max_size = 4
eks_node_desired_size = 1

# Tags
tags = {
  Project     = "trading-app"
  Environment = "production"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
}
```

### Step 2: Initialize Terraform

```bash
cd terraform/
terraform init
```

### Step 3: Plan Deployment

```bash
# Review what will be created
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan
```

### Step 4: Deploy Infrastructure

```bash
# Apply configuration
terraform apply

# Or use saved plan
terraform apply tfplan
```

**⏱️ Deployment Time:** ~25-30 minutes

---

## 📤 Outputs & Credentials

After deployment, get all credentials:

```bash
# View all outputs
terraform output

# Get specific values
terraform output rds_endpoint
terraform output rds_password
terraform output redis_endpoint
terraform output rabbitmq_console_url
terraform output rabbitmq_admin_password
terraform output clickhouse_private_ip
terraform output eks_cluster_name
```

### Save Credentials to File

```bash
# Save all credentials to file
terraform output -json > credentials.json

# Or formatted output
terraform output > credentials.txt
```

---

## 🔐 Access Services

### PostgreSQL (via RDS Proxy)

```bash
# Get credentials
RDS_PROXY=$(terraform output -raw rds_proxy_endpoint)
DB_PASSWORD=$(terraform output -raw rds_password)

# Connect from within VPC (e.g., from EKS pod or EC2)
psql -h $RDS_PROXY -U admin -d mydb
```

### Redis

```bash
# Get endpoint
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)

# Connect (from within VPC)
redis-cli -h $REDIS_ENDPOINT -p 6379
```

### RabbitMQ

```bash
# Get console URL and credentials
RABBITMQ_URL=$(terraform output -raw rabbitmq_console_url)
RABBITMQ_USER=$(terraform output -raw rabbitmq_admin_username)
RABBITMQ_PASS=$(terraform output -raw rabbitmq_admin_password)

echo "RabbitMQ Console: $RABBITMQ_URL"
echo "Username: $RABBITMQ_USER"
echo "Password: $RABBITMQ_PASS"
```

### ClickHouse + Jenkins EC2

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw clickhouse_instance_id)

# Connect via AWS Systems Manager Session Manager
aws ssm start-session --target $INSTANCE_ID

# Once connected:
# - ClickHouse: http://localhost:8123
# - Jenkins: http://localhost:8080
```

### EKS Cluster

```bash
# Configure kubectl
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1

# Verify connection
kubectl get nodes
kubectl get pods -A
```

### Jenkins (via ALB)

```bash
# Get Jenkins URL
JENKINS_URL=$(terraform output -raw jenkins_url)

# Get initial admin password (from EC2)
INSTANCE_ID=$(terraform output -raw clickhouse_instance_id)
aws ssm start-session --target $INSTANCE_ID
# Then: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🔄 Post-Deployment Steps

### 1. Install ClickHouse on EC2

```bash
# SSH into EC2 via Session Manager
INSTANCE_ID=$(terraform output -raw clickhouse_instance_id)
aws ssm start-session --target $INSTANCE_ID

# Run installation script
sudo bash /home/ec2-user/install-clickhouse.sh
```

### 2. Install Jenkins on EC2

```bash
# Already in EC2 session
sudo bash /home/ec2-user/install-jenkins.sh

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 3. Configure EKS kubectl Access

```bash
# Configure kubectl on your local machine
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region us-east-1

# Verify access
kubectl get nodes
```

### 4. Deploy Applications to EKS

```bash
# Set kubectl context
kubectl config use-context $(terraform output -raw eks_cluster_arn)

# Create namespaces
kubectl create namespace prod
kubectl create namespace staging
kubectl create namespace observability

# Deploy sample app (example)
kubectl apply -f k8s/deployments/ -n prod
```

### 5. Configure DNS (if using custom domain)

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

echo "Create DNS records:"
echo "api.example.com -> CNAME -> $ALB_DNS"
echo "jenkins.example.com -> CNAME -> $ALB_DNS"
```

---

## 🧪 Testing Infrastructure

### Test Database Connectivity

```bash
# From EKS pod or EC2
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h $(terraform output -raw rds_proxy_endpoint) -U admin -d mydb -c "SELECT version();"
```

### Test Redis

```bash
kubectl run -it --rm redis-test --image=redis:7 --restart=Never -- \
  redis-cli -h $(terraform output -raw redis_endpoint) PING
```

### Test RabbitMQ

```bash
# Access management console
open $(terraform output -raw rabbitmq_console_url)
```

---

## 🔒 Security Best Practices

### 1. Rotate Passwords

```bash
# Rotate RDS password
aws secretsmanager rotate-secret --secret-id rds-credentials

# Rotate RabbitMQ password
aws secretsmanager rotate-secret --secret-id rabbitmq-credentials
```

### 2. Enable MFA for AWS Account

```bash
# Ensure MFA is enabled for all IAM users
aws iam list-virtual-mfa-devices
```

### 3. Review Security Groups

```bash
# List all security groups
terraform state list | grep security_group

# Verify no 0.0.0.0/0 on sensitive ports
terraform state show module.security_groups.aws_security_group.rds
```

---

## 💰 Cost Management

### Estimate Monthly Cost

```bash
# Install infracost (optional)
brew install infracost

# Register for free API key
infracost register

# Generate cost estimate
infracost breakdown --path .
```

### Monitor Actual Costs

```bash
# AWS Cost Explorer CLI
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project
```

---

## 🗑️ Cleanup (Destroy Infrastructure)

### Destroy Everything

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with 'yes'
```

### Destroy Specific Resources

```bash
# Remove only EKS cluster
terraform destroy -target=module.eks

# Remove only EC2 instance
terraform destroy -target=module.ec2
```

⚠️ **Warning:** This will delete all data. Ensure backups are taken before destroying.

---

## 🐛 Troubleshooting

### Issue: Terraform init fails

```bash
# Clear cache and re-initialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: AWS credentials not found

```bash
# Verify credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

### Issue: EKS nodes not joining cluster

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name $(terraform output -raw eks_cluster_name) \
  --nodegroup-name main-node-group

# Check CloudWatch logs
aws logs tail /aws/eks/$(terraform output -raw eks_cluster_name)/cluster
```

### Issue: Cannot connect to RDS

```bash
# Verify security group rules
terraform state show module.security_groups.aws_security_group.rds

# Test from EC2 in same VPC
aws ssm start-session --target $(terraform output -raw clickhouse_instance_id)
# Then: telnet <rds-endpoint> 5432
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [RDS Proxy Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html)
- [ClickHouse Installation](https://clickhouse.com/docs/en/install)
- [Jenkins on AWS](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/)

---

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Review Terraform plan output
3. Check AWS CloudWatch logs
4. Review context.md for architecture details

---

## 📝 License

This infrastructure code is provided as-is for your AWS deployment.

**Last Updated:** 2025-10-28

