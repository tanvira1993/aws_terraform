# ============================================================================
# Terraform State Backend Configuration
# ============================================================================

# Option 1: Local Backend (Default - Simple, Single User)
# ============================================================================
# Uncomment this if you want to use local state file
# This is fine for testing and single-user scenarios

# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# ============================================================================
# Option 2: S3 Backend (Recommended for Production)
# ============================================================================
# Uncomment and configure this for team collaboration and production use
# Prerequisites:
# 1. Create S3 bucket: aws s3 mb s3://my-terraform-state-bucket
# 2. Create DynamoDB table: 
#    aws dynamodb create-table \
#      --table-name terraform-state-lock \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-bucket"
#     key            = "trading-app/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#     
#     # Optional: Use profile if not using default credentials
#     # profile = "my-aws-profile"
#   }
# }

# ============================================================================
# Instructions:
# ============================================================================
# 1. For local development/testing: Keep both options commented out (uses local backend by default)
# 2. For production: Uncomment Option 2 and configure S3 bucket
#
# To migrate from local to S3 backend:
#   terraform init -migrate-state
#
# To view current state location:
#   terraform show -json | jq '.values.root_module.resources[] | select(.type=="terraform_data")'

