# IAM Permissions Check for Terraform Deployment

## 🔐 NEVER Use Root Account!

**Best Practice:** Always use an IAM user/role with appropriate permissions.  
**Why?** Root account has unlimited access and is a security risk.

---

## 🎯 Required IAM Permissions for Your Deployment

Your IAM user needs these permissions to create all resources:

### 1. **Elastic Load Balancing (ALB)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. **EC2 (Required for ALB, EKS, etc.)**
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:*"
  ],
  "Resource": "*"
}
```

### 3. **Complete IAM Policy for Your Deployment**

Save this as a JSON file and attach to your IAM user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ELBFullAccess",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2FullAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSFullAccess",
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSFullAccess",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElastiCacheFullAccess",
      "Effect": "Allow",
      "Action": [
        "elasticache:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "MQFullAccess",
      "Effect": "Allow",
      "Action": [
        "mq:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMFullAccess",
      "Effect": "Allow",
      "Action": [
        "iam:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3FullAccess",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerFullAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRFullAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMAccess",
      "Effect": "Allow",
      "Action": [
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🔍 How to Check Your Current IAM Permissions

### Option 1: Using AWS CLI

```bash
# Check who you are
aws sts get-caller-identity

# Check if you can create an ALB (test permission)
aws elbv2 describe-load-balancers --region us-east-1

# Check attached policies
aws iam list-attached-user-policies --user-name YOUR_IAM_USERNAME

# Get policy details
aws iam get-policy-version \
  --policy-arn arn:aws:iam::320080583747:policy/POLICY_NAME \
  --version-id v1
```

### Option 2: Using AWS Console

1. Go to: https://console.aws.amazon.com/iam/
2. Click "Users" in the left sidebar
3. Find your IAM user and click on it
4. Look at the "Permissions" tab
5. Check if you have these policies:
   - ✅ `ElasticLoadBalancingFullAccess` (AWS Managed)
   - ✅ `AmazonEC2FullAccess` (AWS Managed)
   - ✅ Or a custom policy with ELB permissions

---

## 🎯 Quick Test: Can You Create an ALB?

Run this test to see if it's a permission issue:

```bash
# Try to list load balancers (should work if you have permissions)
aws elbv2 describe-load-balancers --region us-east-1

# Try to describe account attributes for ALB
aws elbv2 describe-account-limits --region us-east-1
```

**If you get:**
- ✅ `AccessDenied` → IAM permission issue (fixable by you)
- ❌ `OperationNotPermitted` → Account restriction (needs AWS Support)
- ✅ Success with results → You have permissions, but account is restricted

---

## 🔧 How to Add IAM Permissions

### Option A: Attach AWS Managed Policies (Easiest)

1. Go to IAM Console: https://console.aws.amazon.com/iam/
2. Click "Users" → Select your IAM user
3. Click "Add permissions" → "Attach policies directly"
4. Search and select these policies:
   - ✅ `AdministratorAccess` (full access - easiest but least secure)
   - OR individually:
     - `ElasticLoadBalancingFullAccess`
     - `AmazonEC2FullAccess`
     - `AmazonEKSClusterPolicy`
     - `AmazonRDSFullAccess`
     - `AmazonElastiCacheFullAccess`
     - ... (all services you need)

### Option B: Create Custom Policy (More Secure)

1. Go to IAM Console → Policies
2. Click "Create policy"
3. Switch to JSON tab
4. Paste the complete policy JSON from above
5. Name it: `TerraformDeploymentPolicy`
6. Attach to your IAM user

---

## 🚨 Common Error Messages & Meanings

### Error 1: Access Denied
```
An error occurred (AccessDenied) when calling the CreateLoadBalancer operation
```
**Meaning:** Your IAM user lacks permissions  
**Fix:** Add IAM permissions (see above)

### Error 2: Operation Not Permitted (Your Error)
```
OperationNotPermitted: This AWS account currently does not support creating load balancers
```
**Meaning:** Account-level restriction OR insufficient permissions  
**Fix:** Could be either - try the test commands above to confirm

### Error 3: Limit Exceeded
```
LimitExceededException: You have reached the limit for load balancers
```
**Meaning:** Hit service quota (default: 50 ALBs)  
**Fix:** Delete unused ALBs or request quota increase

---

## 📋 Step-by-Step: What You Should Do

### Step 1: Check Your Current Identity
```bash
aws sts get-caller-identity
```

**Output will show:**
```json
{
  "UserId": "AIDAI...",
  "Account": "320080583747",
  "Arn": "arn:aws:iam::320080583747:user/YOUR_USERNAME"
}
```

**If it shows:**
- `"Arn": "arn:aws:iam::320080583747:root"` → You're using root (DON'T!)
- `"Arn": "arn:aws:iam::320080583747:user/..."` → You're using IAM user (GOOD!)

### Step 2: Test ALB Permissions
```bash
# Test if you can describe load balancers
aws elbv2 describe-load-balancers --region us-east-1

# Test if you can see ALB limits
aws elbv2 describe-account-limits --region us-east-1
```

### Step 3: Based on Results

**If you get "AccessDenied":**
→ Add ELB permissions to your IAM user (Option A or B above)
→ Then retry terraform apply

**If you get "OperationNotPermitted":**
→ This is account-level restriction
→ Contact AWS Support (use the template from earlier)

**If it works (shows results):**
→ Your IAM has permissions
→ The Terraform error is account-level
→ Contact AWS Support

---

## ⚡ Quick Fix Commands

### If you need to add permissions quickly (using root or admin account):

```bash
# Get your IAM username
aws sts get-caller-identity --query 'Arn' --output text

# Attach AWS managed policy for ELB
aws iam attach-user-policy \
  --user-name YOUR_IAM_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess

# Attach AWS managed policy for EC2 (required for ALB)
aws iam attach-user-policy \
  --user-name YOUR_IAM_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

**OR attach AdministratorAccess (full access):**
```bash
aws iam attach-user-policy \
  --user-name YOUR_IAM_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

---

## 🎯 Recommended Approach

### For Development/Testing:
```bash
# Attach AdministratorAccess (easiest)
aws iam attach-user-policy \
  --user-name YOUR_IAM_USERNAME \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### For Production:
Create a custom policy with only the permissions you need (see complete policy above).

---

## 🔐 Security Best Practices

1. ✅ **NEVER use root account for daily operations**
2. ✅ **Use IAM user with MFA enabled**
3. ✅ **Use least privilege (only permissions needed)**
4. ✅ **Use IAM roles for EC2/EKS/Lambda instead of access keys**
5. ✅ **Rotate access keys regularly**
6. ✅ **Enable CloudTrail for auditing**

---

## 📞 Still Having Issues?

### Scenario 1: "I added permissions but still get the error"
→ This confirms it's an account-level restriction
→ Contact AWS Support (use template from WHAT_TO_DO_NOW.txt)

### Scenario 2: "I don't have access to add IAM permissions"
→ Ask your AWS account administrator to add permissions
→ Share this document with them

### Scenario 3: "I'm the only user/admin"
→ Sign in with root account (just this once)
→ Add permissions to your IAM user
→ Never use root again

---

## 📝 Summary

| Question | Answer |
|----------|--------|
| Should I use root account? | ❌ **NO! Never for deployments** |
| Should I add IAM permissions? | ✅ **YES! Test and add if needed** |
| How do I know if it's IAM vs account issue? | Run the test commands above |
| What's the safest permission level? | AdministratorAccess for dev, custom policy for prod |
| Can I fix this myself? | If it's IAM: YES. If it's account: NO (need AWS Support) |

---

## 🚀 Next Steps

1. **Run the test commands** (Step 2 above)
2. **If AccessDenied:** Add IAM permissions
3. **If OperationNotPermitted:** Contact AWS Support
4. **After fixing:** Run `terraform apply` again

Good luck! 🎯


