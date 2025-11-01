# ============================================================================
# Data Sources
# ============================================================================

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# EBS Volumes
# ============================================================================

# ClickHouse data volume
resource "aws_ebs_volume" "clickhouse_data" {
  availability_zone = data.aws_subnet.private.availability_zone
  size              = var.clickhouse_data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-clickhouse-data"
    }
  )
}

# Jenkins data volume
resource "aws_ebs_volume" "jenkins_data" {
  availability_zone = data.aws_subnet.private.availability_zone
  size              = var.jenkins_data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-jenkins-data"
    }
  )
}

# ============================================================================
# EC2 Instance
# ============================================================================

resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.ec2_security_group_id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    eks_cluster_name     = var.eks_cluster_name
    eks_cluster_endpoint = var.eks_cluster_endpoint
    aws_region           = data.aws_region.current.name
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-clickhouse-jenkins"
    }
  )
}

# ============================================================================
# Volume Attachments
# ============================================================================

resource "aws_volume_attachment" "clickhouse_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.clickhouse_data.id
  instance_id = aws_instance.main.id
}

resource "aws_volume_attachment" "jenkins_data" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.jenkins_data.id
  instance_id = aws_instance.main.id
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_subnet" "private" {
  id = var.private_subnet_id
}

data "aws_region" "current" {}

