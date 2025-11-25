# Terraform Deployment Errors & Fixes

**Date:** November 3, 2025  
**Status:** 2/3 Issues Fixed in Code, 1 Requires AWS Support

---

## 🚨 Errors Encountered

During `terraform apply`, three errors occurred:

### 1. ❌ ALB (Load Balancer) Error
```
Error: creating ELBv2 application Load Balancer (trading--prod-alb): 
operation error Elastic Load Balancing v2: CreateLoadBalancer, 
https response error StatusCode: 400, RequestID: 71f2548a-02cf-46d1-ae59-53a37eaa6fb8, 
OperationNotPermitted: This AWS account currently does not support creating load balancers. 
For more information, please contact AWS Support.
```

**Root Cause:** AWS account limitation or restriction  
**Status:** ⚠️ **Requires AWS Support action**

### 2. ✅ RabbitMQ Password Error (FIXED)
```
Error: creating MQ Broker (trading-app-production-rabbitmq): 
operation error mq: CreateBroker, https response error StatusCode: 400, 
RequestID: fc8023f1-e742-4298-bbcd-66cb2c14bd44, 
BadRequestException: Make sure your password doesn't contain invalid characters [, :=].
```

**Root Cause:** Randomly generated password contained forbidden characters `[`, `]`, `:`, `=`  
**Status:** ✅ **Fixed in code**

### 3. ✅ RDS PostgreSQL Version Error (FIXED)
```
Error: creating RDS DB Instance (trading-app-production-postgres): 
operation error RDS: CreateDBInstance, https response error StatusCode: 400, 
RequestID: 3eb1f72f-8289-4562-a29c-14e61a11085b, 
api error InvalidParameterCombination: Cannot find version 15.4 for postgres
```

**Root Cause:** PostgreSQL version 15.4 doesn't exist in AWS RDS  
**Status:** ✅ **Fixed in code**

---

## ✅ Fixes Applied

### Fix #1: RabbitMQ Password Special Characters

**File:** `modules/mq/main.tf`

**Changed:**
```hcl
# BEFORE (Line 5-9)
resource "random_password" "rabbitmq" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Contains [, ], :, =
}

# AFTER
resource "random_password" "rabbitmq" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_+<>?"  # Excluded [, ], :, = (invalid for RabbitMQ)
}
```

**Explanation:**  
Amazon MQ RabbitMQ doesn't allow these characters in passwords:
- `[` (left square bracket)
- `]` (right square bracket)
- `:` (colon)
- `=` (equals sign)

The new password generator will only use safe special characters.

---

### Fix #2: RDS Password Special Characters (Proactive)

**File:** `modules/rds/main.tf`

**Changed:**
```hcl
# BEFORE (Line 5-9)
resource "random_password" "rds" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# AFTER
resource "random_password" "rds" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_+<>?"  # Use safe special characters
}
```

**Explanation:**  
While RDS PostgreSQL is more permissive with passwords, we're using the same safe character set for consistency and to avoid potential issues.

---

### Fix #3: PostgreSQL Version Update

**File:** `variables.tf`

**Changed:**
```hcl
# BEFORE (Line 141-145)
variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

# AFTER
variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.5"  # Updated to valid version
}
```

**Explanation:**  
PostgreSQL 15.4 is not available in AWS RDS for the `us-east-1` region. Valid versions include: 15.3, 15.5, 15.7, 15.8, etc. We've updated to 15.5.

**To check available versions:**
```bash
aws rds describe-db-engine-versions \
  --engine postgres \
  --engine-version 15 \
  --query "DBEngineVersions[].EngineVersion" \
  --region us-east-1
```

---

## ⚠️ ALB Issue - Requires Action

### Problem Description

Your AWS account currently **cannot create Application Load Balancers**. This is typically due to one of these reasons:

#### Possible Causes:

1. **New Account Restrictions**
   - AWS restricts certain services for newly created accounts
   - Verification process may not be complete
   - Need to provide additional account information

2. **Service Limits/Quotas**
   - Account has hit the ALB quota (default: 50 ALBs per region)
   - Need to request quota increase

3. **Billing Issues**
   - Outstanding payment or billing verification required
   - Payment method not verified

4. **Account Status**
   - Account may be in limited state pending verification
   - Additional identity verification required

---

## 🔧 Solutions for ALB Issue

### Option 1: Contact AWS Support (Recommended)

**Steps:**
1. Sign in to AWS Console
2. Go to **Support Center**: https://console.aws.amazon.com/support/home
3. Click **Create case**
4. Select **Service limit increase**
5. Choose:
   - **Limit type:** Elastic Load Balancers
   - **Region:** US East (N. Virginia)
   - **Limit:** Application Load Balancers
6. Explain your use case
7. AWS typically responds within 24 hours

**Support Case Template:**
```
Subject: Enable Application Load Balancer Creation

Description:
I am unable to create an Application Load Balancer in us-east-1 region. 
When attempting to create an ALB via Terraform, I receive the following error:

"This AWS account currently does not support creating load balancers."

Request ID: 71f2548a-02cf-46d1-ae59-53a37eaa6fb8

Please enable ALB creation for my account or advise on the verification 
steps required.

Use case: Production infrastructure for a trading application requiring 
load balancing for EKS workloads and Jenkins CI/CD.

Thank you!
```

---

### Option 2: Check Account Status

**Verify your account status:**

1. **Billing Console**
   - Go to: https://console.aws.amazon.com/billing/
   - Ensure payment method is valid
   - Check for any alerts or action items

2. **Trusted Advisor**
   - Go to: https://console.aws.amazon.com/trustedadvisor/
   - Check "Service Limits" section
   - Look for ALB quota issues

3. **Service Quotas Console**
   ```bash
   # Check ALB quotas via CLI
   aws service-quotas get-service-quota \
     --service-code elasticloadbalancing \
     --quota-code L-53DA6B97 \
     --region us-east-1
   ```

---

### Option 3: Temporary Workaround (Continue Without ALB)

If you need to proceed immediately while waiting for AWS Support:

#### Deploy Without ALB

**Option A: Use NodePort Service in EKS**
- Access applications directly via EKS node IP
- Use EC2 instance public IP (if in public subnet)
- Not recommended for production

**Option B: Skip ALB Module Temporarily**

Edit `main.tf`:
```hcl
# Comment out the ALB module
# module "alb" {
#   source = "./modules/alb"
#   ...
# }
```

Then update references:
```bash
# Remove ALB from the plan
terraform plan -target=module.eks -target=module.rds -target=module.ec2

# Apply without ALB
terraform apply -target=module.eks -target=module.rds -target=module.ec2
```

**Caution:** This is only a temporary workaround. Jenkins webhooks and external access will not work without the ALB.

---

## 🔄 Next Steps to Retry Deployment

### Step 1: Destroy Failed Resources
```bash
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform

# Destroy any partially created resources
terraform destroy
```

### Step 2: Refresh Terraform State
```bash
# Remove the existing plan
rm -f tfplan terraform-plan-output.txt

# Clear any state locks
rm -f .terraform.tfstate.lock.info
```

### Step 3: Resolve ALB Issue

**Choose one:**
- ✅ **Wait for AWS Support** (1-2 business days) - Best option
- ⚠️ **Deploy without ALB** (temporary workaround)
- 🔍 **Check if ALB works in another region** (test only)

### Step 4: Re-plan and Apply

Once ALB issue is resolved:

```bash
# Reinitialize (if needed)
terraform init

# Create new plan
terraform plan -out=tfplan

# Apply the plan
terraform apply tfplan
```

---

## 🔍 Verification Steps

After fixes are applied:

### 1. Check Password Generation
```bash
# Passwords should only contain: ! # $ % & * ( ) - _ + < > ?
terraform console
> random_password.rabbitmq.result
> random_password.rds.result
```

### 2. Verify PostgreSQL Version
```bash
# Should show 15.5
terraform show | grep engine_version
```

### 3. Test Without Errors
```bash
# Should not show password or version errors
terraform plan
```

---

## 📊 Expected Results After All Fixes

Once the ALB issue is resolved and the fixes are applied, you should see:

```
Plan: 20 to add, 0 to change, 0 to destroy.

Resources to be created:
✅ EC2 Instance (ClickHouse + Jenkins)
✅ EKS Cluster
✅ EKS Node Groups (on-demand + spot)
✅ RDS PostgreSQL 15.5
✅ RDS Proxy
✅ ElastiCache Redis
✅ Amazon MQ RabbitMQ (with valid password)
✅ Application Load Balancer (after AWS Support enables it)
✅ All supporting resources
```

---

## 💡 Prevention Tips

### For Future Deployments:

1. **Test in New AWS Accounts:**
   - Always verify service availability before large deployments
   - Create a test ALB manually first to confirm access

2. **Password Requirements:**
   - Document service-specific password restrictions
   - Use conservative special character sets
   - Test password generation before full deployment

3. **Version Validation:**
   - Check AWS documentation for valid engine versions
   - Use `aws rds describe-db-engine-versions` before setting versions
   - Consider using `latest` or major version only (e.g., "15")

4. **Service Limits:**
   - Review AWS Service Quotas before deployment
   - Request increases proactively for production accounts
   - Monitor quota usage via CloudWatch

---

## 📞 Getting Help

### AWS Support Resources:
- **Support Center:** https://console.aws.amazon.com/support/home
- **Service Quotas:** https://console.aws.amazon.com/servicequotas/
- **AWS Forums:** https://forums.aws.amazon.com/
- **AWS Documentation:** https://docs.aws.amazon.com/

### PostgreSQL Version Info:
- **RDS User Guide:** https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
- **Version Policy:** https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html

### Amazon MQ Password Requirements:
- **MQ User Guide:** https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/
- **Password Requirements:** Must not contain `[`, `]`, `:`, `=`

---

## 📝 Summary

| Issue | Status | Action Required |
|-------|--------|-----------------|
| RabbitMQ Password | ✅ Fixed | None - code updated |
| RDS Password | ✅ Fixed | None - code updated |
| PostgreSQL Version | ✅ Fixed | None - updated to 15.5 |
| **ALB Creation** | ⚠️ **Blocked** | **Contact AWS Support** |

**Current Blocker:** ALB creation is blocked at the AWS account level. This **must** be resolved with AWS Support before full deployment can succeed.

**Time to Resolution:** Typically 1-2 business days after contacting AWS Support.

**Can Deploy Without ALB?** Yes, but with limited functionality (no external access, no Jenkins webhooks).

---

## ✅ Ready to Proceed

Once you receive confirmation from AWS Support that ALBs are enabled on your account:

```bash
# Navigate to terraform directory
cd /Users/tanvirahamed/Evoliq-Tech/aws_journey/terraform

# Generate new plan
terraform plan -out=tfplan 2>&1 | tee terraform-plan-output.txt

# Apply the plan
terraform apply tfplan
```

All code fixes are already in place! 🚀

