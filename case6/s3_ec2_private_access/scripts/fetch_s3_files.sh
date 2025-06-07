#!/bin/bash

# Install CloudWatch Agent from S3
aws s3 cp s3://amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm /tmp/
sudo rpm -Uvh /tmp/amazon-cloudwatch-agent.rpm

# Ensure config directory exists
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

# Write CloudWatch Agent config
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/ec2/cloud-init-output",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Create images directory for fedora user
mkdir -p /home/fedora/images
chown fedora:fedora /home/fedora/images

# Fetch files from S3
aws s3 cp s3://secure-private-s3-bucket-case/ /home/fedora/images/ --recursive
