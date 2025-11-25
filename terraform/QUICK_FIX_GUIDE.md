# Quick Fix Guide - Terraform Deployment Errors

## ✅ What I Fixed (Completed)

### 1. Code Fixes
- ✅ **RabbitMQ Password:** Removed invalid characters `[`, `]`, `:`, `=`
- ✅ **RDS Password:** Updated for consistency
- ✅ **PostgreSQL Version:** Changed from 15.4 → 15.5 (valid version)
- ✅ **Tainted Resources:** Marked passwords for regeneration

### 2. Resources Status

**Successfully Created (108 resources):**
- ✅ VPC, Subnets, IGW, NAT Gateway
- ✅ Security Groups (all 7)
- ✅ IAM Roles and Policies
- ✅ EKS Cluster + Node Groups + Addons
- ✅ EC2 Instance (ClickHouse/Jenkins)
- ✅ ElastiCache Redis
- ✅ ECR Repositories
- ✅ S3 Bucket
- ✅ Secrets Manager (secrets created, versions need update)

**Failed to Create (3 resources):**
- ❌ Application Load Balancer (AWS account limitation)
- ❌ RDS PostgreSQL (wrong version - now fixed)
- ❌ RabbitMQ Broker (invalid password - now fixed)

---

## 🚨 CRITICAL: ALB Account Issue

**Your AWS account cannot create Load Balancers.**

### Immediate Action Required:

**Option 1: Contact AWS Support (RECOMMENDED)**

1. Go to: https://console.aws.amazon.com/support/home
2. Click "Create case"
3. Select "Account and billing" → "Account"
4. Use this template:

```
Subject: Enable Application Load Balancer Creation

Hi AWS Support,

I am unable to create Application Load Balancers in us-east-1. 
When attempting via Terraform, I receive:

Error: "This AWS account currently does not support creating load balancers"
Request ID: 71f2548a-02cf-46d1-ae59-53a37eaa6fb8

Please enable ALB/ELB creation for my account.

Use case: Production infrastructure for a trading application.

Account ID: 320080583747
Region: us-east-1

Thank you!
```

**Expected Response Time:** 1-2 business days

---

**Option 2: Deploy Without ALB (Temporary)**

If you need to proceed immediately:

```bash
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform

# Apply without ALB module
terraform apply -target=module.rds -target=module.mq
```

**Note:** Without ALB, you won't have:
- External access to Jenkins
- Webhook support for CI/CD
- Load balancing for EKS services

---

## 🚀 Next Steps (After AWS Support Enables ALB)

### Step 1: Apply Remaining Resources

```bash
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform

# Apply the fixes (will create RDS + RabbitMQ with new passwords)
terraform apply
```

**This will:**
- ✅ Create RDS PostgreSQL 15.5
- ✅ Create RabbitMQ with valid password
- ✅ Create Application Load Balancer (if account is enabled)
- ✅ Update Secrets Manager with new passwords

### Step 2: Verify Deployment

```bash
# Check all resources are created
terraform state list | wc -l
# Should show ~111 resources

# Get outputs
terraform output
```

### Step 3: Get Service Credentials

```bash
# Extract all credentials
./get-credentials.sh

# View credentials
cat SERVICE_CREDENTIALS.txt
```

### Step 4: Configure Services

1. **Connect to EC2 (ClickHouse/Jenkins):**
   ```bash
   # Get instance ID
   INSTANCE_ID=$(terraform output -raw clickhouse_instance_id)
   
   # Connect via Session Manager
   aws ssm start-session --target $INSTANCE_ID
   
   # Inside the instance:
   sudo /home/ec2-user/install-clickhouse.sh
   sudo /home/ec2-user/install-jenkins.sh
   ```

2. **Configure EKS:**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name trading-app-production-eks
   
   # Verify
   kubectl get nodes
   ```

3. **Access Jenkins:**
   ```bash
   # Get Jenkins URL
   terraform output jenkins_url
   
   # Open in browser
   # Get initial password from EC2 instance
   ```

---

## 📊 What's Different Now

### Password Generation (Fixed)

**Before:**
```hcl
override_special = "!#$%&*()-_=+[]{}<>:?"  # ❌ Contains []:=
```

**After:**
```hcl
override_special = "!#$%&*()-_+<>?"  # ✅ Only safe characters
```

### PostgreSQL Version (Fixed)

**Before:**
```hcl
default = "15.4"  # ❌ Doesn't exist
```

**After:**
```hcl
default = "15.5"  # ✅ Valid version
```

---

## 🔍 Troubleshooting

### If terraform apply still fails:

**Check password characters:**
```bash
terraform console
> random_password.rabbitmq.result
> random_password.rds.result
# Should not contain [ ] : =
```

**Check PostgreSQL version:**
```bash
grep -A 3 "rds_engine_version" terraform.tfvars.example
# Should show 15.5
```

**Check available PostgreSQL versions:**
```bash
aws rds describe-db-engine-versions \
  --engine postgres \
  --query "DBEngineVersions[?contains(EngineVersion, '15.')].EngineVersion" \
  --region us-east-1
```

---

## 📝 Files Updated

1. ✅ `modules/mq/main.tf` - Fixed RabbitMQ password
2. ✅ `modules/rds/main.tf` - Fixed RDS password
3. ✅ `variables.tf` - Updated PostgreSQL version
4. ✅ `DEPLOYMENT_ERRORS_AND_FIXES.md` - Detailed explanation
5. ✅ `QUICK_FIX_GUIDE.md` - This file

---

## ⚡ Quick Commands

```bash
# Navigate to terraform directory
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform

# Show current state
terraform state list

# Plan with fixes
terraform plan

# Apply (when ALB is enabled)
terraform apply

# Get outputs
terraform output

# Get credentials
./get-credentials.sh

# Connect to EC2
aws ssm start-session --target $(terraform output -raw clickhouse_instance_id)

# Configure EKS
aws eks update-kubeconfig --region us-east-1 --name trading-app-production-eks
```

---

## 💰 Current Cost

**Resources Running:** ~$603/month (estimated)

**Breakdown:**
- EKS Cluster: $73/month
- EKS Nodes: 1x m5.large = $70/month
- EC2 (ClickHouse/Jenkins): 1x m5.large = $70/month
- RDS (when created): db.m5.large = $185/month
- Redis: cache.t3.small = $36/month
- RabbitMQ (when created): mq.t3.micro = $17/month
- NAT Gateway: $35/month
- Other: ~$117/month

**Note:** Stop/terminate resources if not needed immediately to save costs.

---

## 🎯 Summary

| Item | Status | Action |
|------|--------|--------|
| Code Fixes | ✅ Complete | None |
| Password Generation | ✅ Fixed | Will regenerate on next apply |
| PostgreSQL Version | ✅ Fixed | Now using 15.5 |
| Existing Resources | ✅ Running | Keep or destroy based on need |
| **ALB Creation** | ⚠️ **BLOCKED** | **Contact AWS Support** |

---

## 📞 Need Help?

- **AWS Support:** https://console.aws.amazon.com/support/home
- **Detailed Guide:** See `DEPLOYMENT_ERRORS_AND_FIXES.md`
- **Plan Summary:** See `TERRAFORM_PLAN_SUMMARY.md`

---

**All code fixes are complete. Only AWS account limitation remains!** 🚀

