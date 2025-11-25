#!/bin/bash

# ============================================================================
# IAM Permissions Check Script
# ============================================================================
# This script checks if your IAM user has the necessary permissions
# to create AWS resources for the Terraform deployment.
# ============================================================================

set -e

echo "============================================================================"
echo "                   AWS IAM PERMISSIONS CHECK"
echo "============================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# 1. Check Current Identity
# ============================================================================
echo -e "${BLUE}[1/6] Checking current AWS identity...${NC}"
echo ""

IDENTITY=$(aws sts get-caller-identity 2>&1)

if [ $? -eq 0 ]; then
    echo "$IDENTITY" | jq '.'
    
    # Check if using root account
    if echo "$IDENTITY" | grep -q "root"; then
        echo -e "${RED}⚠️  WARNING: You are using the ROOT account!${NC}"
        echo -e "${RED}   This is NOT recommended for security reasons.${NC}"
        echo -e "${YELLOW}   Please create an IAM user and use that instead.${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ Using IAM user (Good!)${NC}"
        echo ""
    fi
else
    echo -e "${RED}❌ Failed to get identity. Are your AWS credentials configured?${NC}"
    echo "   Run: aws configure"
    exit 1
fi

# ============================================================================
# 2. Test ELB/ALB Permissions
# ============================================================================
echo -e "${BLUE}[2/6] Testing Elastic Load Balancing permissions...${NC}"
echo ""

ELB_TEST=$(aws elbv2 describe-load-balancers --region us-east-1 2>&1)
ELB_EXIT_CODE=$?

if [ $ELB_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ ELB describe permission: GRANTED${NC}"
    echo "   Found $(echo "$ELB_TEST" | jq '.LoadBalancers | length') load balancers"
    echo ""
elif echo "$ELB_TEST" | grep -q "AccessDenied"; then
    echo -e "${RED}❌ ELB describe permission: DENIED${NC}"
    echo -e "${YELLOW}   You need ElasticLoadBalancingFullAccess policy${NC}"
    echo ""
    IAM_ISSUE=true
elif echo "$ELB_TEST" | grep -q "OperationNotPermitted"; then
    echo -e "${RED}❌ ELB operations: NOT PERMITTED${NC}"
    echo -e "${YELLOW}   This is an ACCOUNT-LEVEL restriction${NC}"
    echo -e "${YELLOW}   You must contact AWS Support${NC}"
    echo ""
    ACCOUNT_RESTRICTION=true
else
    echo -e "${YELLOW}⚠️  Unknown error:${NC}"
    echo "$ELB_TEST"
    echo ""
fi

# ============================================================================
# 3. Test ELB Account Limits
# ============================================================================
echo -e "${BLUE}[3/6] Checking ELB account limits...${NC}"
echo ""

LIMITS=$(aws elbv2 describe-account-limits --region us-east-1 2>&1)
LIMITS_EXIT_CODE=$?

if [ $LIMITS_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Can check account limits${NC}"
    echo "$LIMITS" | jq '.Limits[] | select(.Name == "application-load-balancers")'
    echo ""
elif echo "$LIMITS" | grep -q "AccessDenied"; then
    echo -e "${RED}❌ Cannot check account limits (AccessDenied)${NC}"
    echo ""
    IAM_ISSUE=true
else
    echo -e "${YELLOW}⚠️  Unknown error:${NC}"
    echo "$LIMITS"
    echo ""
fi

# ============================================================================
# 4. Test EC2 Permissions (Required for ALB)
# ============================================================================
echo -e "${BLUE}[4/6] Testing EC2 permissions (required for ALB)...${NC}"
echo ""

EC2_TEST=$(aws ec2 describe-vpcs --region us-east-1 2>&1)
EC2_EXIT_CODE=$?

if [ $EC2_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ EC2 permissions: GRANTED${NC}"
    echo ""
elif echo "$EC2_TEST" | grep -q "UnauthorizedOperation"; then
    echo -e "${RED}❌ EC2 permissions: DENIED${NC}"
    echo -e "${YELLOW}   You need AmazonEC2FullAccess policy${NC}"
    echo ""
    IAM_ISSUE=true
else
    echo -e "${YELLOW}⚠️  Unknown error:${NC}"
    echo "$EC2_TEST"
    echo ""
fi

# ============================================================================
# 5. Test IAM Permissions
# ============================================================================
echo -e "${BLUE}[5/6] Testing IAM permissions...${NC}"
echo ""

IAM_TEST=$(aws iam list-roles --max-items 1 2>&1)
IAM_TEST_EXIT_CODE=$?

if [ $IAM_TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ IAM permissions: GRANTED${NC}"
    echo ""
elif echo "$IAM_TEST" | grep -q "AccessDenied"; then
    echo -e "${YELLOW}⚠️  IAM permissions: LIMITED${NC}"
    echo -e "${YELLOW}   You may not be able to create IAM roles${NC}"
    echo ""
    IAM_ISSUE=true
else
    echo -e "${YELLOW}⚠️  Unknown error:${NC}"
    echo "$IAM_TEST"
    echo ""
fi

# ============================================================================
# 6. List Attached IAM Policies
# ============================================================================
echo -e "${BLUE}[6/6] Checking your IAM policies...${NC}"
echo ""

# Extract username from identity
USERNAME=$(echo "$IDENTITY" | jq -r '.Arn' | awk -F'/' '{print $NF}')

if [ "$USERNAME" != "null" ] && [ ! -z "$USERNAME" ]; then
    echo "IAM User: $USERNAME"
    echo ""
    
    POLICIES=$(aws iam list-attached-user-policies --user-name "$USERNAME" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Attached policies:${NC}"
        echo "$POLICIES" | jq -r '.AttachedPolicies[] | "  - \(.PolicyName)"'
        echo ""
    else
        echo -e "${YELLOW}⚠️  Cannot list policies (may need permissions)${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine IAM username${NC}"
    echo ""
fi

# ============================================================================
# Summary and Recommendations
# ============================================================================
echo "============================================================================"
echo -e "                         ${BLUE}DIAGNOSIS${NC}"
echo "============================================================================"
echo ""

if [ "${ACCOUNT_RESTRICTION}" = true ]; then
    echo -e "${RED}🚨 DIAGNOSIS: ACCOUNT-LEVEL RESTRICTION${NC}"
    echo ""
    echo "Your AWS account is restricted from creating load balancers."
    echo "This is NOT an IAM permission issue."
    echo ""
    echo -e "${YELLOW}ACTION REQUIRED:${NC}"
    echo "  1. Contact AWS Support"
    echo "  2. Use the template in: WHAT_TO_DO_NOW.txt"
    echo "  3. Wait for AWS to enable ALB creation (1-2 business days)"
    echo ""
    echo -e "${BLUE}Support URL: https://console.aws.amazon.com/support/home${NC}"
    echo ""
elif [ "${IAM_ISSUE}" = true ]; then
    echo -e "${YELLOW}🔐 DIAGNOSIS: IAM PERMISSIONS ISSUE${NC}"
    echo ""
    echo "Your IAM user lacks necessary permissions."
    echo ""
    echo -e "${GREEN}YOU CAN FIX THIS:${NC}"
    echo ""
    echo "Option 1 - Quick Fix (Full Access):"
    echo "  aws iam attach-user-policy \\"
    echo "    --user-name $USERNAME \\"
    echo "    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess"
    echo ""
    echo "Option 2 - Specific Permissions:"
    echo "  aws iam attach-user-policy \\"
    echo "    --user-name $USERNAME \\"
    echo "    --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    echo ""
    echo "  aws iam attach-user-policy \\"
    echo "    --user-name $USERNAME \\"
    echo "    --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    echo ""
    echo "See CHECK_IAM_PERMISSIONS.md for detailed instructions."
    echo ""
else
    echo -e "${GREEN}✅ PERMISSIONS LOOK GOOD!${NC}"
    echo ""
    echo "Your IAM user appears to have the necessary permissions."
    echo ""
    echo "If Terraform still fails with ALB creation, it's likely an"
    echo "account-level restriction. Contact AWS Support."
    echo ""
fi

echo "============================================================================"
echo ""
echo -e "${BLUE}📚 For more information, see:${NC}"
echo "  - CHECK_IAM_PERMISSIONS.md (detailed IAM guide)"
echo "  - WHAT_TO_DO_NOW.txt (next steps)"
echo "  - DEPLOYMENT_ERRORS_AND_FIXES.md (error explanations)"
echo ""
echo "============================================================================"


