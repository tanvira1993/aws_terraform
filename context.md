# Infrastructure Context

## Overview
This document provides an overview of the deployment and infrastructure setup for the platform running on **AWS**.  
The system uses a mix of **managed AWS services** (for reliability and reduced ops overhead) and **EC2-based components** (for flexibility and cost optimization).

---

## 🧱 Core Components

### 1. Amazon EKS (Elastic Kubernetes Service)
- **Purpose:** Runs all microservices, internal APIs, and centralized logging stack
- **Nodes:** m5.large with Cluster Autoscaler
  - **Minimum:** 1 node (baseline workload)
  - **Maximum:** 4 nodes (scales during high-load periods)
  - **Strategy:** On-demand for baseline, Spot instances for additional nodes
- **Deployment:** Each microservice is containerized and deployed as a Kubernetes Deployment with a corresponding Service and Ingress
- **Container Registry:** Amazon ECR (Elastic Container Registry) - private repositories
- **Namespaces:**
  - `staging` — for staging workloads
  - `prod` — for production workloads
  - `observability` — for monitoring, logging, and tracing stack (Prometheus + OpenTelemetry + Loki + Grafana)

### 2. Amazon RDS (PostgreSQL)
- **Purpose:** Primary relational database for application data
- **Instance Type:** db.m5.large (2 vCPU, 8GB RAM)
- **Storage:** 100GB gp2 (General Purpose SSD)
- **Deployment:** Single-AZ deployment (cost-optimized)
- **Connection Management:** RDS Proxy for efficient connection pooling and failover
- **Backups:** Automated daily snapshots with 7-day retention
- **High Availability:** Point-in-time recovery enabled; RDS Proxy provides connection resilience

### 3. ClickHouse + Jenkins (Shared EC2)
- **Purpose:** 
  - **ClickHouse:** High-performance analytical datastore for reporting and log analytics
  - **Jenkins:** CI/CD automation server
  - **Kubectl Admin:** Direct Kubernetes cluster management and operations
- **Deployment:** Co-located on single EC2 instance (resource-isolated via systemd)
- **Instance Type:** m5.large (2 vCPU, 8GB RAM)
- **Storage:** 
  - ClickHouse data: EBS gp3 (100GB) with daily snapshots
  - Jenkins workspace: EBS gp3 (50GB) with manual backups
- **Kubernetes Access:** 
  - kubectl installed with EKS cluster admin permissions
  - AWS IAM Authenticator configured for seamless authentication
  - Kubeconfig automatically configured for cluster access
- **Security:** Accessible only via AWS Systems Manager Session Manager (no SSH)
- **Resource Allocation:**
  - ClickHouse: 5GB RAM, priority CPU access
  - Jenkins: 2GB RAM, builds run on EKS agents
  - kubectl: On-demand usage for cluster operations

### 4. Redis (ElastiCache)
- **Purpose:** Caching, session management, and queue support
- **Type:** Redis (cluster mode disabled, single node)
- **Instance:** cache.t3.small
- **Access:** VPC-only access from EKS workloads
- **Backup:** Daily snapshots with 3-day retention

### 5. RabbitMQ (Amazon MQ)
- **Purpose:** Message broker for inter-service communication
- **Type:** RabbitMQ (managed Amazon MQ service)
- **Instance Class:** mq.t3.micro (single AZ, cost-optimized)
- **Usage:** Handles async tasks, background processing, and event queues
- **Access:** VPC-only, accessible from EKS and shared EC2

---

## ⚙️ CI/CD Pipeline — Jenkins

### Jenkins Setup
- **Jenkins Master:** Runs on shared m5.large EC2 instance (co-located with ClickHouse)
- **Location:** Private subnet (no direct internet exposure)
- **Webhook Access:** Receives Git webhooks via ALB routing (public endpoint: `https://jenkins.yourdomain.com`)
  - ALB forwards webhook paths (`/github-webhook/`, `/gitlab-webhook/`, `/bitbucket-webhook/`) to Jenkins EC2:8080
  - SSL/TLS termination at ALB with ACM certificate
  - Security Group: Jenkins EC2 accepts traffic only from ALB security group
- **Agents:** Dynamically spawned as Kubernetes pods in EKS using Jenkins Kubernetes plugin
- **Storage:** Dedicated EBS gp3 volume (50GB) for `/var/lib/jenkins` (persistent workspace and job data)
- **Backups:** Manual/on-demand EBS snapshots only (no automated daily backups)
- **Monitoring:** Logs and metrics collected by in-cluster observability stack (OpenTelemetry → Loki/Prometheus)
- **Resource Limits:** Constrained to 2GB RAM via systemd; CPU shares adjusted for ClickHouse priority

### Pipeline Flow
1. **Trigger:** Git push or PR merge sends webhook to ALB → Jenkins (or optional polling fallback)
2. **Build:** Docker image built for each microservice (in EKS pod agents)
3. **Push:** Image pushed to Amazon ECR (IAM-authenticated, no credentials needed)
4. **Deploy:** Jenkins deploys new image to EKS using `kubectl` or Helm
5. **Verify:** Kubernetes rollout status checked
6. **Notify:** Slack or email notification on success/failure

**ECR Push Example:**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t api-server:${GIT_COMMIT} .
docker tag api-server:${GIT_COMMIT} <account-id>.dkr.ecr.us-east-1.amazonaws.com/api-server:${GIT_COMMIT}
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/api-server:${GIT_COMMIT}
```

### Manual Operations
- **Direct kubectl access** from shared EC2 instance for:
  - Troubleshooting pods and services
  - Viewing logs and events (`kubectl logs`, `kubectl describe`)
  - Scaling deployments manually
  - Applying configuration changes
  - Debugging network issues
  - Emergency rollbacks
- **Access Method:** SSH into EC2 via AWS Systems Manager Session Manager → kubectl commands

### Jenkinsfile Template
Each repository contains a `Jenkinsfile` defining:
- Build → Test → Push → Deploy stages.
- Environment variables (region, repo, image tag, etc.).
- Rollback support via `kubectl rollout undo`.

### Kubectl Admin Setup (Shared EC2)
- **Installation:**
  - kubectl binary installed and configured
  - AWS CLI v2 with IAM authenticator
  - Helm 3 for package management
  
- **Configuration:**
  ```bash
  # Kubeconfig auto-generated on EC2 instance
  aws eks update-kubeconfig --name <cluster-name> --region <region>
  
  # Verify access
  kubectl get nodes
  kubectl get pods --all-namespaces
  ```

- **Common Operations:**
  - View cluster status: `kubectl cluster-info`
  - Check pod logs: `kubectl logs -f <pod-name> -n <namespace>`
  - Describe resources: `kubectl describe pod <pod-name>`
  - Scale deployments: `kubectl scale deployment <name> --replicas=3`
  - Apply manifests: `kubectl apply -f deployment.yaml`
  - Emergency rollback: `kubectl rollout undo deployment/<name>`
  - Port forwarding: `kubectl port-forward svc/<service> 8080:80`

- **Security:**
  - Access logged via CloudTrail (EKS API calls)
  - Session Manager audit logs in CloudWatch
  - RBAC enforced at cluster level

---

## 📦 Supporting Services

### Amazon ECR (Elastic Container Registry)
- **Purpose:** Private container registry for all microservice images
- **Storage:** ~50GB average (with lifecycle cleanup)
- **Integration:** 
  - Native IAM-based authentication (no credentials needed)
  - Jenkins uses EC2 IAM role for push/pull
  - EKS nodes use worker role for image pulls
- **Tagging Strategy:** Git commit SHA + semantic versioning
- **Lifecycle Policy:** 
  - Keep last 10 tagged images per repository
  - Auto-delete untagged images after 7 days
- **Security:** 
  - Automatic vulnerability scanning (CVE detection)
  - Private repositories only (VPC endpoint support)
  - CloudTrail audit logging
- **Cost:** ~$5/month (50GB × $0.10/GB)
- **Ops Benefits:**
  - No external credentials to manage
  - No rate limits (unlimited pulls)
  - Faster image pulls (same region)
  - Automatic image scanning
  - Native AWS integration

### Observability Stack (EKS)
- **Namespace:** `observability` (dedicated namespace for monitoring and logging infrastructure)

#### **Components:**

**1. Prometheus (Metrics Collection & Storage)**
- Time-series database for metrics
- Scrapes metrics from all pods and services
- Retention: 15 days in-cluster
- HA deployment (2 replicas)
- Resource: ~2GB RAM, 1 CPU

**2. OpenTelemetry Collector (Unified Telemetry)**
- Collects logs, metrics, and traces
- Protocol-agnostic (OTLP, Jaeger, Zipkin)
- Routes data to appropriate backends
- DaemonSet on all nodes
- Resource: ~512MB RAM per node, 0.5 CPU

**3. Loki (Log Aggregation)**
- S3-backed log storage
- Retention: 7 days (S3 lifecycle policy)
- Receives logs from OpenTelemetry Collector
- Resource: ~1GB RAM, 0.5 CPU

**4. Grafana (Unified Visualization)**
- Single pane of glass for logs, metrics, and traces
- Pre-configured dashboards
- Alerting and notifications
- Resource: ~512MB RAM, 0.5 CPU

**5. Node Exporter (System Metrics)**
- DaemonSet on all EKS nodes
- Exposes system-level metrics (CPU, memory, disk, network)
- Scraped by Prometheus
- Resource: ~128MB RAM per node, 0.1 CPU

**6. Kube-State-Metrics**
- Kubernetes resource metrics (pods, deployments, services)
- Cluster-level insights
- Resource: ~256MB RAM, 0.2 CPU

#### **Architecture:**
```
Application Pods → OpenTelemetry SDK → OTel Collector → Loki (logs) / Prometheus (metrics) / Jaeger (traces)
                                              ↓
                                          Grafana (visualization)
```

#### **Storage:**
- **Prometheus:** Local PVC (50GB) for 15-day metrics retention
- **Loki:** S3 bucket for 7-day log retention
- **Jaeger (optional):** S3 for trace data

#### **Total Resource Allocation:**
- **CPU:** ~2.8 vCPU reserved
- **RAM:** ~4.5GB reserved
- **Storage:** 50GB PVC (Prometheus) + S3 (Loki logs)

### Amazon S3
- **Access Method:** S3 Gateway VPC Endpoint (no NAT Gateway charges, private routing)
- **Primary Use Cases:**
  1. **Application & System Logs** (Loki storage backend) - 7-day retention
  2. **ClickHouse Backups** (daily snapshots) - 15-day retention
  3. **Build Artifacts** (optional shared storage)

- **Storage Structure:**
  ```
  s3://bucket-name/
    ├── loki/
    │   ├── chunks/     (log data, 7-day retention)
    │   └── index/      (log indexes, 7-day retention)
    └── backups/
        └── clickhouse/ (15-day retention)
  ```

- **Lifecycle Policies:**
  - **Logs:** Auto-delete after 7 days
  - **ClickHouse Backups:** Auto-delete after 15 days
  - **Build Artifacts:** Optional, 30-day retention

- **Estimated Monthly Storage:**
  - Logs: ~200-250GB (with 7-day rotation)
  - ClickHouse Backups: ~50-100GB (with 15-day rotation)
  - Total Average: ~300GB

- **Cost Optimization:** 
  - S3 Standard with lifecycle policies for automated deletion
  - S3 Gateway VPC Endpoint eliminates NAT Gateway charges (~$5/month savings)

### Amazon CloudWatch
- **Metrics Only:** System and application metrics (no log storage)
  - CPU, memory, disk usage for EC2 and EKS nodes
  - RDS performance metrics
  - Custom application metrics
- **Alarms:** Configured for critical thresholds (CPU >80%, disk >85%, etc.)
- **Cost Optimization:** Minimal usage, metrics only (no logs)

---

## 🧠 Security & Access Control

### IAM Roles
- **Shared EC2 Role (ClickHouse + Jenkins + Kubectl Admin):**
  - **EKS Full Admin Access** (cluster-admin RBAC permissions)
  - **EKS Describe/List Access** (view clusters, nodegroups, addons)
  - **ECR Full Access** (push/pull images, create repositories, scan images)
  - S3 Read/Write Access (backups, snapshots, artifacts, Loki logs)
  - CloudWatch Metrics Write Access
  - RDS Describe Access
  - Secrets Manager Read Access (application secrets, deploy keys)
  - Systems Manager Session Manager Access (secure remote access)

- **EKS Worker Role:**
  - **ECR Read Access** (pull images only)
  - S3 Read/Write Access (Loki log storage, backup artifacts)
  - CloudWatch Metrics Write Access
  - Secrets Manager Read Access (application secrets)
  - EBS CSI Driver permissions (for PVC management)

- **Loki Service Account (IRSA):**
  - S3 Full Access to logging bucket (loki/* prefix)
  - Scoped to logging namespace only

### Network
- All services run within a single VPC
- **Private subnets:** EKS nodes, RDS, shared EC2 (ClickHouse + Jenkins), Redis, RabbitMQ
- **Public subnet:** Application Load Balancer only (for external traffic)
- **Remote Access:** AWS Systems Manager Session Manager (no SSH, no bastion host)
- **ALB Routing:**
  - Application traffic: `https://api.yourdomain.com` → EKS Ingress Controller
  - Jenkins webhooks: `https://jenkins.yourdomain.com` → Jenkins EC2:8080
  - SSL/TLS termination at ALB (AWS Certificate Manager)
- **VPC Endpoints (Gateway):**
  - **S3 Gateway Endpoint:** No-cost, routes all S3 traffic privately (bypasses NAT Gateway)
  - Used by: Loki (log storage), ClickHouse backups, build artifacts, ECR image layers
  - **Cost Benefit:** Eliminates ~$13-15/month in NAT Gateway data processing fees
- **VPC Endpoints (Interface - Optional):**
  - ECR API, ECR Docker, CloudWatch, Secrets Manager, Systems Manager
  - Cost: ~$7.20/month per endpoint (consider based on traffic volume)
- **Security Groups:** Least privilege - only necessary ports open between services
  - ALB → EKS nodes (80/443) and Shared EC2 (8080 for Jenkins)
  - EKS nodes → RDS (5432), Redis (6379), ClickHouse (8123, 9000), RabbitMQ (5672)
  - Shared EC2 → EKS API Server (443) for kubectl operations
  - Jenkins agents in EKS → Jenkins master (50000)
  - VPC Endpoints → All services in private subnets (443)

### EKS RBAC Configuration
- **Shared EC2 IAM Role** mapped to `system:masters` group in aws-auth ConfigMap
- **Cluster-admin** permissions for full kubectl access
- **Access Scope:** 
  - All namespaces (staging, prod, logging, kube-system)
  - Full resource management (pods, deployments, services, etc.)
  - Node management and cluster-level operations

---

## 📊 Monitoring & Observability

### Full-Stack Observability (EKS-based)

| Component | Tool | Description |
|------------|------|-------------|
| **Application Logs** | OpenTelemetry → Loki → S3 | All pod logs collected and stored in S3 (7-day retention) |
| **System Logs** | OTel Collector → Loki → S3 | EC2 and node logs collected centrally |
| **Application Metrics** | Prometheus | Custom app metrics, request rates, latency, errors |
| **System Metrics** | Node Exporter → Prometheus | CPU, memory, disk, network per node |
| **Kubernetes Metrics** | Kube-State-Metrics → Prometheus | Pod, deployment, service resource usage |
| **Distributed Tracing** | OpenTelemetry → Jaeger (optional) | End-to-end request tracing across services |
| **Unified Visualization** | Grafana | Single dashboard for logs, metrics, traces |
| **ClickHouse Monitoring** | Prometheus exporter + Grafana | Query performance and resource tracking |
| **Jenkins Monitoring** | Prometheus Plugin | Job metrics, build duration, queue length |
| **AWS Resources** | CloudWatch Agent | EC2, RDS, Redis, RabbitMQ metrics |
| **Alerting** | Grafana Alerting + Prometheus AlertManager | Multi-channel alerts (Slack, email, PagerDuty) |

### Data Retention
- **Logs (Loki → S3):** 7 days (automated S3 lifecycle deletion)
- **Metrics (Prometheus):** 15 days in-cluster
- **Traces (Jaeger):** 3 days (optional)
- **CloudWatch Metrics:** 15 months (AWS default)

### Observability Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Application Pods                         │
│  (instrumented with OpenTelemetry SDK)                      │
└──────────────────┬──────────────────────────────────────────┘
                   │ Logs, Metrics, Traces
                   ↓
┌─────────────────────────────────────────────────────────────┐
│           OpenTelemetry Collector (DaemonSet)               │
│  - Receives telemetry data (OTLP protocol)                  │
│  - Processes and routes to backends                         │
└──────┬──────────────────┬───────────────────┬───────────────┘
       │                  │                   │
       ↓                  ↓                   ↓
   ┌───────┐         ┌──────────┐       ┌─────────┐
   │ Loki  │         │Prometheus│       │ Jaeger  │
   │  ↓    │         │ (15 days)│       │(optional)│
   │  S3   │         │          │       └─────────┘
   │(7days)│         └──────────┘
   └───────┘              │
       │                  │
       └──────────┬───────┘
                  ↓
         ┌─────────────────┐
         │    Grafana       │
         │ (Unified View)   │
         └─────────────────┘
```

---

## 💰 Cost Optimization

| Component | Strategy | Monthly Savings |
|------------|-----------|-----------------|
| **EKS Nodes** | Min 1, max 4 m5.large; use Spot for autoscaled nodes (60-90% discount) | ~$140 |
| **RDS** | db.m5.large single-AZ (vs Multi-AZ) with RDS Proxy | ~$150 |
| **Shared EC2** | Co-locate ClickHouse + Jenkins on single m5.large | ~$70 |
| **Container Registry** | Amazon ECR with lifecycle policies (vs external registries) | Cost-effective |
| **Observability Stack** | Self-hosted in EKS instead of managed services (Datadog/NewRelic) | ~$200+ |
| **Log Storage** | S3-backed Loki instead of CloudWatch Logs (99% cheaper) | ~$55 |
| **S3 VPC Endpoint** | Gateway endpoint for S3 (no NAT Gateway charges for S3 traffic) | ~$13-15 |
| **Jenkins Backups** | Manual EBS snapshots only (no daily automated backups) | ~$5 |
| **S3 Lifecycle** | Auto-delete logs after 7 days, ClickHouse after 15 days | ~$10 |
| **Redis** | Small instance (cache.t3.small), minimal data | ~$10 |
| **RabbitMQ** | Managed Amazon MQ t3.micro (low message volume) | Cost-effective |
| **EBS Volumes** | gp3 instead of gp2 (20% cheaper, better performance) | ~$10 |

**Total Estimated Monthly Cost: $423-495** (avg ~$458, peak ~$612 during 2 high-load days)

---

## 🔄 Backup & Disaster Recovery

| Component | Backup Strategy | Retention | RTO |
|------------|----------------|-----------|-----|
| **RDS** | Automated daily snapshot + point-in-time recovery | 7 days | ~15 min |
| **ClickHouse** | Daily S3 data export | 15 days | ~30 min |
| **Jenkins** | Manual/on-demand EBS snapshot only | On-demand | ~10 min |
| **EKS Config** | GitOps - all manifests versioned in Git repo | Indefinite | ~5 min |
| **Redis** | Daily snapshot via ElastiCache | 1 day | ~5 min |
| **RabbitMQ** | Amazon MQ automated backup | 7 days | ~10 min |
| **Application Logs** | S3 storage via Loki | 7 days | N/A |

**Recovery Process:**
1. **RDS:** Restore from snapshot or point-in-time to new instance
2. **ClickHouse:** Restore data from S3 backup (15-day retention)
3. **Shared EC2:** Launch new m5.large, attach EBS volumes or restore from snapshot
4. **EKS:** Redeploy from Git using Jenkins or `kubectl apply`
5. **Logs:** Available in S3 for past 7 days (queryable via Loki/Grafana)

---

## 🔐 Secrets Management
- **Storage:** All secrets stored in **AWS Secrets Manager** (encrypted at rest with KMS)
- **EKS Access:** Secrets mounted into pods via External Secrets Operator or CSI driver
- **Jenkins Access:** Uses Credentials Binding Plugin integrated with Secrets Manager
- **Rotation:** Database credentials rotated automatically every 90 days
- **Access Control:** IAM role-based access, no hardcoded credentials

---

## 🚀 Deployment Environments

| Environment | Namespace | Description |
|--------------|------------|-------------|
| Staging | `staging` | Optional pre-production environment |
| Production | `prod` | Stable live environment |
| Observability | `observability` | Monitoring, logging, and tracing stack (Prometheus + OpenTelemetry + Loki + Grafana + Node Exporter) |

---

## 🔍 Summary

**Goal:**  
A **production-grade**, **cost-optimized** (~$500/month), and scalable environment leveraging AWS-managed services and Kubernetes, designed for workloads with **2 high-load days per month** and minimal resource usage otherwise.

**Key Highlights:**
- ✅ **EKS with intelligent autoscaling** (1-4 m5.large nodes, Spot instances for scale-out)
- ✅ **Cost-optimized RDS** (db.m5.large single-AZ with RDS Proxy for connection pooling)
- ✅ **Consolidated EC2** (ClickHouse + Jenkins + kubectl admin on single m5.large)
- ✅ **Direct kubectl access** from shared EC2 for cluster management and troubleshooting
- ✅ **Production-grade observability** (Prometheus + OpenTelemetry + Loki + Grafana + Node Exporter)
- ✅ **Full-stack telemetry** (logs, metrics, distributed tracing in unified platform)
- ✅ **Amazon ECR registry** (IAM-based auth, automatic scanning, no external dependencies)
- ✅ **Managed Redis + RabbitMQ** (small instances, reliable managed services)
- ✅ **Full CI/CD automation** via Jenkins with dynamic EKS agents and webhook support via ALB
- ✅ **Unified monitoring** (single Grafana dashboard for all observability data)
- ✅ **Secure architecture** (private subnets, IAM roles, SSM access, no SSH, ALB for external access)
- ✅ **Disaster recovery ready** (ClickHouse 15-day backups, RDS snapshots, GitOps)

**Monthly Cost:** $431-467 (avg ~$467 actual usage, ~$513 with 10% buffer) | Peak: ~$622 during high-load days

**Scaling Strategy:** Auto-scales compute resources during high-load periods while maintaining minimal baseline costs

---

## 💵 Detailed Monthly Cost Breakdown

### Baseline Costs (Normal Operation - 28 days)
| Service | Specification | Unit Cost | Quantity | Monthly Cost |
|---------|---------------|-----------|----------|--------------|
| **EKS Control Plane** | Managed K8s | $0.10/hour | 730 hours | $73.00 |
| **EKS Node (baseline)** | m5.large on-demand | $0.096/hour | 730 hours | $70.08 |
| **RDS PostgreSQL** | db.m5.large single-AZ, 100GB gp2 | ~$0.112/hour + storage | 730 hours | $82.00 |
| **RDS Proxy** | Single proxy, low connection usage | ~$0.025/hour | 730 hours | $18.00 |
| **Shared EC2** | m5.large on-demand | $0.096/hour | 730 hours | $70.08 |
| **ElastiCache Redis** | cache.t3.small | ~$0.034/hour | 730 hours | $24.82 |
| **Amazon MQ** | mq.t3.micro RabbitMQ | ~$0.025/hour | 730 hours | $18.25 |
| **EBS Volumes** | gp3: 250GB (EC2: 150GB + Prometheus: 50GB + Loki cache: 50GB) | $0.08/GB-month | 250 GB | $20.00 |
| **S3 Storage** | Logs (7d) + ClickHouse backups (15d) | ~$0.023/GB | ~300GB avg | $7.00 |
| **ECR Storage** | Container images (~50GB with lifecycle cleanup) | $0.10/GB-month | 50 GB | $5.00 |
| **S3 VPC Endpoint** | Gateway endpoint (free) | $0.00 | - | $0.00 |
| **Data Transfer** | Inter-AZ + outbound (S3 via VPC endpoint, no NAT) | Variable | - | $5.00 |
| **CloudWatch** | Metrics only (minimal) | Variable | - | $5.00 |
| **Secrets Manager** | ~10 secrets | $0.40/secret | 10 | $4.00 |
| **NAT Gateway** | Single NAT | $0.045/hour + data | 730 hours | $35.00 |
| **ALB** | Application Load Balancer (app traffic + Jenkins webhooks) | $0.025/hour + LCU | 730 hours | $20.00 |
| **Route 53** | Hosted zone + queries | $0.50/zone + queries | 1 zone | $2.00 |
| | | | **BASELINE TOTAL** | **$456.23** |

### High-Load Days (2 days/month - autoscaling)
| Service | Additional Resources | Unit Cost | Hours | Additional Cost |
|---------|---------------------|-----------|-------|-----------------|
| **EKS Spot Nodes** | 2× m5.large (70% discount) | $0.029/hour | 48 hours × 2 | $5.57 |
| **Data Transfer** | Increased traffic | Variable | - | $5.00 |
| | | | **HIGH-LOAD TOTAL** | **$10.57** |

### 📊 Final Monthly Cost Summary
```
Baseline (28 days):        $456.23
High-Load (2 days):        $ 10.57
─────────────────────────────────
Subtotal:                  $466.80
Buffer (10%):              $ 46.68
─────────────────────────────────
TOTAL ESTIMATED:           $513.48/month
```

**✅ Within $500/month budget!** (Actual usage ~$467 without buffer, under budget by ~$33)
**💰 S3 VPC Endpoint Savings:** ~$5/month in data transfer costs (no NAT Gateway charges for S3)

**Cost Scaling Scenarios:**
- **Minimum** (1 node, low traffic): ~$431/month ✅
- **Average** (1.3 nodes, normal): ~$467/month ✅
- **Peak** (4 nodes on-demand for full 2 days): ~$622/month
- **Optimized Peak** (Spot instances): ~$513/month (with buffer) ✅

**Storage & Retention Summary:**
- **Container Images (ECR):** ~50GB with automatic lifecycle cleanup (last 10 tagged images)
- **Application Logs (S3 via Loki):** 7-day retention (~200-250GB/month)
- **Metrics (Prometheus PVC):** 15-day retention (50GB)
- **ClickHouse Backups (S3):** 15-day retention (~50-100GB/month)
- **Total S3 Usage:** ~300GB average with lifecycle auto-deletion
- **Total EBS Usage:** 250GB (EC2: 150GB + Observability: 100GB)

---

**Author:** DevOps Architecture Team  
**Last Updated:** 2025-10-20
