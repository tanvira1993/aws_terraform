# ============================================================================
# Random Suffix for Unique Bucket Name
# ============================================================================

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# ============================================================================
# S3 Bucket
# ============================================================================

resource "aws_s3_bucket" "main" {
  bucket = "${var.bucket_prefix}-${var.environment}-${random_string.bucket_suffix.result}"

  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_prefix}-${var.environment}-bucket"
    }
  )
}

# ============================================================================
# S3 Bucket Versioning
# ============================================================================

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================================
# S3 Bucket Server-Side Encryption
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================================================
# S3 Bucket Public Access Block
# ============================================================================

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# S3 Bucket Lifecycle Policy
# ============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Loki logs - 7 day retention
  rule {
    id     = "delete-loki-logs"
    status = "Enabled"

    filter {
      prefix = "loki/"
    }

    expiration {
      days = var.lifecycle_logs_expiration_days
    }
  }

  # ClickHouse backups - 15 day retention
  rule {
    id     = "delete-clickhouse-backups"
    status = "Enabled"

    filter {
      prefix = "backups/clickhouse/"
    }

    expiration {
      days = var.lifecycle_clickhouse_backup_expiration_days
    }
  }
}

# ============================================================================
# S3 VPC Gateway Endpoint (FREE - saves NAT Gateway costs)
# ============================================================================

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-s3-endpoint"
    }
  )
}

# ============================================================================
# Data Source for Region
# ============================================================================

data "aws_region" "current" {}

