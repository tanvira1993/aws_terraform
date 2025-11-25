# Terraform Deployment Plan Summary

**Generated:** November 3, 2025  
**Project:** trading-app  
**Environment:** production  
**Region:** us-east-1  

---

## 📊 Overview

**Total Changes:** 20 resources to be created

**Action:** This is a fresh deployment with no existing resources to modify or destroy.

---

## 🏗️ Infrastructure Components

### 1. Application Load Balancer (ALB)
- **Name:** `trading--prod-alb`
- **Type:** Application Load Balancer
- **Accessibility:** Public (Internet-facing)
- **Subnets:** 2 public subnets across availability zones
- **Security Group:** Configured for HTTP (80) and HTTPS (443)
- **Listeners:**
  - HTTP listener on port 80 → forwards to EKS target group
  - Listener rule for Jenkins (priority 100) → forwards to Jenkins target group
- **Configuration:**
  - Idle timeout: 60 seconds
  - HTTP/2 enabled
  - Deletion protection: disabled
  - WAF integration: disabled

**What gets created:**
- ✅ ALB main resource
- ✅ HTTP listener (port 80)
- ✅ Listener rule for Jenkins routing
- ✅ Target group attachment for Jenkins EC2 instance

---

### 2. EC2 Instance (ClickHouse + Jenkins)
- **Name:** `trading-app-production-clickhouse-jenkins`
- **Instance Type:** m5.large
- **AMI:** Amazon Linux 2 (ami-0601422bf6afa8ac3)
- **Subnet:** Private subnet (subnet-07ca2636e8eb03e5b)
- **IAM Profile:** trading-app-production-ec2-profile
- **Security Group:** EC2-specific security group

**Storage:**
- **Root Volume:** 50 GB gp3 (encrypted)
- **ClickHouse Data Volume:** /dev/sdf (existing vol-0a4490955188fb3c1)
- **Jenkins Data Volume:** /dev/sdg (existing vol-0b37ef4e694e3a1c0)

**Installed Software:**
- Docker
- kubectl
- AWS CLI
- Installation scripts for ClickHouse and Jenkins (manual execution required)

**Access:**
- Systems Manager Session Manager (no SSH key required)

**What gets created:**
- ✅ EC2 instance
- ✅ Volume attachment for ClickHouse data
- ✅ Volume attachment for Jenkins data

---

### 3. Amazon EKS Cluster
- **Cluster Name:** `trading-app-production-eks`
- **Version:** 1.28
- **Role:** trading-app-production-eks-cluster-role
- **Subnets:** 2 private subnets
- **Endpoint Access:**
  - Private: enabled
  - Public: enabled
- **Security Group:** eks-cluster security group
- **Logging Enabled:** api, audit, authenticator, controllerManager, scheduler

**EKS Addons:**
- ✅ CoreDNS (DNS resolution in cluster)
- ✅ kube-proxy (network proxy)
- ✅ VPC CNI (pod networking)

**What gets created:**
- ✅ EKS cluster
- ✅ CoreDNS addon
- ✅ kube-proxy addon
- ✅ VPC CNI addon

---

### 4. EKS Node Groups

#### On-Demand Node Group
- **Name:** `trading-app-production-node-group`
- **Instance Type:** m5.large
- **Capacity Type:** ON_DEMAND
- **Scaling:**
  - Min: 1 node
  - Desired: 1 node
  - Max: 4 nodes
- **Disk Size:** 50 GB per node
- **Role:** trading-app-production-eks-node-role
- **Update Config:** Max unavailable = 1

#### Spot Instance Node Group
- **Name:** `trading-app-production-spot-node-group`
- **Instance Type:** m5.large
- **Capacity Type:** SPOT (up to 70% cost savings)
- **Scaling:**
  - Min: 0 nodes
  - Desired: 0 nodes (starts scaled down)
  - Max: 3 nodes
- **Disk Size:** 50 GB per node
- **Role:** trading-app-production-eks-node-role
- **Update Config:** Max unavailable = 1

**What gets created:**
- ✅ On-demand node group
- ✅ Spot instance node group

---

### 5. RDS PostgreSQL Database
- **Identifier:** `trading-app-production-postgres`
- **Engine:** PostgreSQL 15.4
- **Instance Class:** db.m5.large
- **Storage:** 100 GB gp2 (encrypted)
- **Username:** admin
- **Password:** Auto-generated (stored in Secrets Manager)
- **Database Name:** mydb
- **Backup:**
  - Retention: 7 days
  - Window: 03:00-04:00 UTC
- **Maintenance Window:** Monday 04:00-05:00 UTC
- **Multi-AZ:** Not configured (cost optimization)
- **Publicly Accessible:** No
- **CloudWatch Logs:** postgresql, upgrade
- **Security Group:** RDS-specific security group
- **Subnet Group:** trading-app-production-db-subnet-group

**What gets created:**
- ✅ RDS PostgreSQL instance
- ✅ Secrets Manager secret version with credentials

---

### 6. RDS Proxy
- **Name:** `trading-app-production-rds-proxy`
- **Engine Family:** POSTGRESQL
- **Role:** trading-app-production-rds-proxy-role
- **TLS Required:** Yes
- **Subnets:** 2 private subnets
- **Authentication:** Secrets Manager (uses RDS credentials secret)

**Connection Pool Configuration:**
- Max connections: 100% of RDS max connections
- Max idle connections: 50%
- Connection borrow timeout: 120 seconds

**What gets created:**
- ✅ RDS Proxy
- ✅ Default target group
- ✅ Proxy target (links to RDS instance)

**Purpose:** Manages connection pooling for up to 200 concurrent database connections efficiently.

---

### 7. ElastiCache Redis
- **Cluster ID:** `trading-app-production-redis`
- **Engine:** Redis 7.0
- **Node Type:** cache.t3.small
- **Number of Nodes:** 1 (single node, cost optimized)
- **Port:** 6379
- **Parameter Group:** default.redis7
- **Subnet Group:** trading-app-production-redis-subnet-group
- **Security Group:** Redis-specific security group

**Backup Configuration:**
- Snapshot window: 03:00-05:00 UTC
- Snapshot retention: 3 days

**Maintenance:**
- Window: Monday 05:00-07:00 UTC
- Auto minor version upgrade: enabled

**What gets created:**
- ✅ ElastiCache Redis cluster

---

### 8. Amazon MQ (RabbitMQ)
- **Broker Name:** `trading-app-production-rabbitmq`
- **Engine:** RabbitMQ 3.11.20
- **Deployment Mode:** SINGLE_INSTANCE (cost optimized)
- **Instance Type:** mq.t3.micro
- **Subnets:** 1 private subnet
- **Security Group:** RabbitMQ-specific security group
- **Publicly Accessible:** No
- **Auto Minor Version Upgrade:** No

**Access:**
- AMQP port: 5672
- AMQPS port: 5671 (TLS)
- Management console: 15672

**Logging:**
- General logs: enabled

**Credentials:**
- Stored in AWS Secrets Manager

**What gets created:**
- ✅ Amazon MQ RabbitMQ broker

---

## 🔐 Security Configuration

### Secrets Management
All sensitive credentials are stored in AWS Secrets Manager:
- **RDS Credentials:** `trading-app-production-rds-credentials-yA4cTp`
- **RabbitMQ Credentials:** `trading-app-production-rabbitmq-credentials-fEuA3r`

### Security Groups
The plan uses pre-existing security groups:
- ALB Security Group: `sg-04139925d2dd0fa06`
- EC2 Security Group: `sg-0e49be1e92d55b291`
- EKS Cluster Security Group: `sg-0215502b9f9fb533c`
- EKS Nodes Security Group: `sg-091cf58efb190ac64`
- RDS Security Group: `sg-0817cbcf771bad251`
- Redis Security Group: `sg-041cf7e539d222484`
- RabbitMQ Security Group: `sg-042a2840674fb97b5`

### IAM Roles
The plan uses pre-existing IAM roles:
- EKS Cluster Role: `trading-app-production-eks-cluster-role`
- EKS Node Role: `trading-app-production-eks-node-role`
- RDS Proxy Role: `trading-app-production-rds-proxy-role`
- EC2 Instance Profile: `trading-app-production-ec2-profile`

---

## 🌐 Networking

### VPC
- **VPC ID:** vpc-06c54df0b029df33f (existing)

### Subnets (existing)
- **Public Subnets:**
  - subnet-0ba06ca80ebc41180
  - subnet-0af7403d6cf94dfcd
- **Private Subnets:**
  - subnet-07ca2636e8eb03e5b
  - subnet-0df8e3aeacc2bf2f3

### Internet Connectivity
- **Internet Gateway:** igw-017f194489553051c (existing)
- **NAT Gateway:** nat-05bbf173916ba0329 (existing)
- **Elastic IP:** eipalloc-0d4d7dca2be1873ed (existing)
- **S3 VPC Endpoint:** vpce-0479cb25fd9913a75 (existing, Gateway type)

---

## 📦 Supporting Resources

### S3 Bucket
- **Bucket Name:** `trading-app-production-waryfvp1` (existing)
- **Purpose:** Logs, backups, application data
- **Encryption:** Enabled (AES-256)
- **Versioning:** Enabled
- **Public Access:** Blocked
- **Lifecycle:** Configured for old version cleanup

### ECR Repositories (existing)
- `trading-app-production-frontend`
- `trading-app-production-api-server`
- `trading-app-production-worker`

All ECR repositories have lifecycle policies to keep only the last 10 images.

---

## 📤 Outputs Available After Deployment

Once deployed, the following outputs will be available:

### Access URLs
- `alb_dns_name` - ALB DNS name for accessing applications
- `jenkins_url` - Public URL to access Jenkins (via ALB)
- `jenkins_private_url` - Private URL to access Jenkins directly
- `api_url` - API endpoint URL
- `rabbitmq_console_url` - RabbitMQ management console URL

### Service Endpoints
- `rds_endpoint` - RDS database endpoint
- `rds_proxy_endpoint` - RDS Proxy endpoint (recommended for applications)
- `redis_endpoint` - Redis cluster endpoint
- `rabbitmq_endpoint` - RabbitMQ broker endpoint
- `eks_cluster_endpoint` - EKS cluster API endpoint
- `clickhouse_private_ip` - ClickHouse instance private IP

### Connection Strings
- `rds_connection_string` - PostgreSQL connection string (sensitive)
- `redis_connection_string` - Redis connection string
- `rabbitmq_amqp_connection_string` - RabbitMQ AMQP connection string (sensitive)
- `clickhouse_connection_string` - ClickHouse connection string

### Deployment Information
- `deployment_summary` - Comprehensive deployment details
- `eks_cluster_arn` - EKS cluster ARN
- `alb_arn` - ALB ARN
- `alb_zone_id` - ALB Route 53 zone ID
- `all_credentials` - All service credentials in one output (sensitive)

### Management Commands
- `ec2_ssm_connect_command` - Command to connect to EC2 via Session Manager

---

## 💰 Estimated Monthly Costs

Based on the planned resources (us-east-1 region):

| Service | Configuration | Est. Monthly Cost |
|---------|--------------|------------------|
| **EC2 (ClickHouse/Jenkins)** | 1x m5.large (on-demand, 730 hrs) | ~$70 |
| **EBS Volumes** | 50GB root + 200GB data (350GB total) | ~$35 |
| **EKS Cluster** | Control plane | $73 |
| **EKS On-Demand Nodes** | 1x m5.large (730 hrs) | ~$70 |
| **EKS Spot Nodes** | 0x m5.large (scaled to 0) | $0 |
| **RDS PostgreSQL** | db.m5.large (730 hrs) + 100GB storage | ~$185 |
| **RDS Proxy** | Proxy + connections | ~$45 |
| **ElastiCache Redis** | cache.t3.small (730 hrs) | ~$36 |
| **Amazon MQ (RabbitMQ)** | mq.t3.micro (730 hrs) | ~$17 |
| **ALB** | 730 hrs + minimal data transfer | ~$20 |
| **NAT Gateway** | 730 hrs + 5GB data transfer | ~$35 |
| **S3** | 50GB storage + minimal requests | ~$1.50 |
| **Secrets Manager** | 2 secrets | ~$0.80 |
| **CloudWatch Logs** | RDS logs (estimate) | ~$5 |
| **Data Transfer** | Inter-AZ + NAT (estimate) | ~$10 |

**TOTAL ESTIMATED:** ~$603/month

### Cost Optimization Notes:
- ✅ Spot nodes are scaled to 0 by default (can scale up when needed for ~70% savings)
- ✅ Single-AZ RDS (no Multi-AZ) saves ~50% on RDS costs
- ✅ Single-instance RabbitMQ saves ~50% vs. cluster mode
- ✅ S3 VPC Gateway Endpoint eliminates NAT charges for S3 traffic
- ✅ No CloudWatch monitoring for EKS (using self-hosted Prometheus/Grafana)
- ✅ Shared EC2 instance for ClickHouse + Jenkins
- ⚠️ Consider Reserved Instances for 1-year commitment (save 30-40%)
- ⚠️ Consider Savings Plans for compute (save 20-30%)

---

## 🚀 Next Steps

### To Deploy This Plan:

```bash
# Apply the saved plan
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform
terraform apply "tfplan"
```

### Post-Deployment Tasks:

1. **Configure ClickHouse:**
   ```bash
   # Connect to EC2 instance
   aws ssm start-session --target <instance-id>
   
   # Run ClickHouse installation script
   sudo /home/ec2-user/install-clickhouse.sh
   ```

2. **Configure Jenkins:**
   ```bash
   # Run Jenkins installation script
   sudo /home/ec2-user/install-jenkins.sh
   
   # Get initial admin password (will be displayed after installation)
   ```

3. **Configure EKS:**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --region us-east-1 --name trading-app-production-eks
   
   # Verify connection
   kubectl get nodes
   ```

4. **Get Service Credentials:**
   ```bash
   # Run the credentials extraction script
   ./get-credentials.sh
   
   # Credentials will be saved to SERVICE_CREDENTIALS.txt
   ```

5. **Deploy Applications to EKS:**
   - Configure kubectl context
   - Deploy your application manifests
   - Set up ingress/services to connect to ALB
   - Configure applications with database/cache/queue endpoints

6. **Set Up Jenkins:**
   - Access Jenkins via ALB URL
   - Install required plugins (Kubernetes, Docker, etc.)
   - Configure Kubernetes cloud (EKS cluster connection)
   - Set up Jenkins agents to run as EKS pods
   - Create CI/CD pipelines

7. **Verify All Services:**
   - Test database connectivity via RDS Proxy
   - Test Redis cache operations
   - Test RabbitMQ message queuing
   - Test ClickHouse queries
   - Test Jenkins builds
   - Test application access via ALB

---

## ⚠️ Important Notes

### Resource Dependencies
The plan will create resources in the correct order based on dependencies:
1. Network-independent resources (RDS, Redis, RabbitMQ, ALB, EC2)
2. EKS cluster (depends on IAM roles and subnets)
3. EKS node groups (depends on EKS cluster)
4. EKS addons (depends on EKS cluster)
5. RDS Proxy and target (depends on RDS instance)
6. ALB target attachments (depends on EC2 instance)

### Manual Steps Required
- ClickHouse installation (run script on EC2 after deployment)
- Jenkins installation (run script on EC2 after deployment)
- Jenkins configuration (initial setup wizard)
- Application deployment to EKS
- DNS configuration (point your domain to ALB if needed)

### Data Persistence
- EBS volumes for ClickHouse and Jenkins are already created and will be attached
- Data on these volumes will persist across EC2 instance replacements
- RDS automated backups are configured (7-day retention)
- Redis snapshots are configured (3-day retention)

### Security Best Practices
- All services are in private subnets (except ALB)
- No SSH access (use Session Manager instead)
- Secrets are managed via AWS Secrets Manager
- IAM roles follow least privilege principle
- Security groups restrict traffic to necessary ports only
- Encryption at rest enabled for RDS and EBS volumes

---

## 📞 Support

For issues or questions:
1. Check the Terraform logs for error details
2. Review the AWS console for resource status
3. Consult the `terraform/README.md` for detailed setup instructions
4. Check `terraform/FINAL_SUMMARY.md` for additional guidance

---

**Plan saved to:** `tfplan`  
**Human-readable output:** `terraform-plan-readable.txt`  
**This summary:** `TERRAFORM_PLAN_SUMMARY.md`

