provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"
}
# Public Subnet for Bastion Host
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.0.0/24"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.1.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = var.key_name # Ensure this key exists

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastionHost"
  }
}
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.189.48.199/32"] # Replace with your IP
  }
  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["10.1.0.0/24"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "private_sg" {
  name   = "private-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["10.1.0.0/24"]
  }
  ingress {
    description = "Allow HTTPS from VPC to VPC endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.private_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "cloudwatch-logs-endpoint"
  }
}


resource "aws_s3_bucket" "image_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = "image-bucket"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "image_bucket_lifecycle" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    id     = "expire-after-30-days"
    status = "Enabled"

    filter {
      prefix = "" # Applies to all objects
    }

    expiration {
      days = 30
    }
  }
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.image_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.image_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailAcl",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.image_bucket.arn
      }
    ]
  })
}


resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_access_role_v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",

    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2_s3_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = [aws_s3_bucket.image_bucket.arn]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.image_bucket.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents" 
        ],
        Resource = "*"
      },
       {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::amazoncloudwatch-agent/*"
      }
    ]
  })
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  user_data = file("scripts/fetch_s3_files.sh")

  tags = {
    Name = "S3PrivateEC2"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile_v2"
  role = aws_iam_role.ec2_role.name
}

resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/ec2/cloud-init-output"
  retention_in_days = 7
}

resource "aws_cloudtrail" "trail" {
  name                          = "s3-ec2-trail"
  s3_bucket_name                = aws_s3_bucket.image_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}


