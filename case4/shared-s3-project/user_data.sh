#!/bin/bash
# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
 apt-get install -y docker.io
 systemctl start docker
 systemctl enable docker
 usermod -aG docker ubuntu

# Install dependencies for s3fs
 apt-get install -y automake build-essential libfuse-dev libcurl4-openssl-dev \
                   libxml2-dev mime-support git libssl-dev

# Install s3fs-fuse from source
cd /tmp
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
make install

# Mount point directory
sudo mkdir -p /mnt/s3bucket

# Mount the S3 bucket using IAM role
# NOTE: Replace "your-bucket-name" with your actual bucket name, or pass it via Terraform
echo "shared-s3-bucket-demo /mnt/s3bucket fuse.s3fs _netdev,allow_other,iam_role=auto,use_path_request_style,url=https://s3.amazonaws.com 0 0" >> /etc/fstab
sudo s3fs shared-s3-bucket-demo /mnt/s3bucket -o iam_role=auto -o allow_other
