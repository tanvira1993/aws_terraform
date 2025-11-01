#!/bin/bash
set -e

# ============================================================================
# EC2 User Data Script for ClickHouse + Jenkins
# ============================================================================

# Update system
yum update -y

# Install required packages
yum install -y curl wget git jq docker

# Start Docker
systemctl start docker
systemctl enable docker

# ============================================================================
# Configure EBS Volumes
# ============================================================================

# Wait for volumes to attach
sleep 10

# Format and mount ClickHouse data volume
if [ ! -e /dev/nvme1n1 ]; then
    mkfs -t ext4 /dev/nvme1n1
fi
mkdir -p /var/lib/clickhouse
mount /dev/nvme1n1 /var/lib/clickhouse
echo "/dev/nvme1n1 /var/lib/clickhouse ext4 defaults,nofail 0 2" >> /etc/fstab

# Format and mount Jenkins data volume
if [ ! -e /dev/nvme2n1 ]; then
    mkfs -t ext4 /dev/nvme2n1
fi
mkdir -p /var/lib/jenkins
mount /dev/nvme2n1 /var/lib/jenkins
echo "/dev/nvme2n1 /var/lib/jenkins ext4 defaults,nofail 0 2" >> /etc/fstab

# ============================================================================
# Install AWS CLI v2
# ============================================================================

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# ============================================================================
# Install kubectl
# ============================================================================

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Configure kubectl for EKS
mkdir -p /root/.kube
aws eks update-kubeconfig --name ${eks_cluster_name} --region ${aws_region}

# ============================================================================
# Install Helm
# ============================================================================

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ============================================================================
# Create Installation Scripts
# ============================================================================

cat > /home/ec2-user/install-clickhouse.sh << 'EOF'
#!/bin/bash
set -e

echo "Installing ClickHouse..."

# Add ClickHouse repository
yum install -y yum-utils
yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo

# Install ClickHouse
yum install -y clickhouse-server clickhouse-client

# Configure ClickHouse
mkdir -p /var/lib/clickhouse
chown clickhouse:clickhouse /var/lib/clickhouse

# Start ClickHouse
systemctl start clickhouse-server
systemctl enable clickhouse-server

echo "ClickHouse installed successfully!"
echo "HTTP port: 8123"
echo "Native port: 9000"
echo "Test connection: clickhouse-client"
EOF

chmod +x /home/ec2-user/install-clickhouse.sh

cat > /home/ec2-user/install-jenkins.sh << 'EOF'
#!/bin/bash
set -e

echo "Installing Jenkins..."

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Java
amazon-linux-extras install java-openjdk11 -y

# Install Jenkins
yum install -y jenkins

# Configure Jenkins home
mkdir -p /var/lib/jenkins
chown jenkins:jenkins /var/lib/jenkins

# Start Jenkins
systemctl start jenkins
systemctl enable jenkins

# Wait for Jenkins to start
sleep 30

# Print initial admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "====================================="
    echo "Jenkins Initial Admin Password:"
    cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
    echo "====================================="
fi

echo "Jenkins installed successfully!"
echo "Jenkins will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8080"
EOF

chmod +x /home/ec2-user/install-jenkins.sh

# ============================================================================
# Create Info File
# ============================================================================

cat > /home/ec2-user/README.txt << EOF
=============================================================================
  ClickHouse + Jenkins + kubectl Admin Server
=============================================================================

INSTALLATION:
  1. Install ClickHouse: sudo /home/ec2-user/install-clickhouse.sh
  2. Install Jenkins:    sudo /home/ec2-user/install-jenkins.sh

CLICKHOUSE:
  - HTTP Port:   8123
  - Native Port: 9000
  - Test:        clickhouse-client

JENKINS:
  - Port: 8080
  - Initial password: /var/lib/jenkins/secrets/initialAdminPassword

KUBECTL:
  - Pre-configured for EKS cluster: ${eks_cluster_name}
  - Test: kubectl get nodes

EBS VOLUMES:
  - ClickHouse data: /var/lib/clickhouse (mounted)
  - Jenkins data:    /var/lib/jenkins (mounted)

AWS REGION: ${aws_region}
=============================================================================
EOF

chown ec2-user:ec2-user /home/ec2-user/*

echo "User data script completed!"

