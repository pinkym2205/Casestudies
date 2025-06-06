resource "aws_launch_template" "this" {
  name_prefix   = "${var.environment}-lt"
  image_id      = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.key_name
  
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode<<-EOF
  #!/bin/bash
  apt-get update -y
  apt-get install -y 

  mkdir -p /var/www/html
  echo "Hello from ${var.environment} environment!" > /var/www/html/index.html

  systemctl enable nginx
  systemctl start nginx
EOFuser_data = base64encode(<<-EOF
  #!/bin/bash
  apt-get update -y
  apt-get install -y nginx

  mkdir -p /var/www/html

  cat <<EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>${var.environment^} Environment</title>
    <style>
        body {
            background-color: #e0f7e9;
            color: #2d572c;
            font-family: Arial, sans-serif;
            text-align: center;
            padding-top: 100px;
        }
        h1 {
            font-size: 48px;
        }
        p {
            font-size: 24px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Hello from ${var.environment} Environment!</h1>
    <p>This is the \${var.environment} version of the application.</p>
</body>
</html>
EOT

  systemctl enable nginx
  systemctl start nginx
EOF
)


  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-asg-instance"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.environment}-asg"
  vpc_zone_identifier       = var.public_subnets
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  target_group_arns         = [var.alb_target_group_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["103.189.48.199/32"] 
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}