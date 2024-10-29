provider "aws" {
  region = "us-east-1"
}

# Step 1: Create a VPC
resource "aws_vpc" "yash_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "yash-vpc"
  }
}

# Step 2: Create Subnets
resource "aws_subnet" "yash_subnet_a" {
  vpc_id                  = aws_vpc.yash_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "yash-subnet-a"
  }
}

resource "aws_subnet" "yash_subnet_b" {
  vpc_id                  = aws_vpc.yash_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "yash-subnet-b"
  }
}

# Step 3: Create a Security Group
resource "aws_security_group" "yash_allow_http" {
  vpc_id = aws_vpc.yash_vpc.id
  name   = "yash-allow-http"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "yash-allow-http"
  }
}

# Step 4: Create an Internet Gateway
resource "aws_internet_gateway" "yash_internet_gateway" {
  vpc_id = aws_vpc.yash_vpc.id

  tags = {
    Name = "yash-internet-gateway"
  }
}

# Step 5: Create a Route Table
resource "aws_route_table" "yash_route_table" {
  vpc_id = aws_vpc.yash_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yash_internet_gateway.id
  }

  tags = {
    Name = "yash-route-table"
  }
}

# Step 6: Associate Route Table with Subnets
resource "aws_route_table_association" "yash_route_table_association_a" {
  subnet_id      = aws_subnet.yash_subnet_a.id
  route_table_id = aws_route_table.yash_route_table.id
}

resource "aws_route_table_association" "yash_route_table_association_b" {
  subnet_id      = aws_subnet.yash_subnet_b.id
  route_table_id = aws_route_table.yash_route_table.id
}

# Step 7: Create a Launch Template
resource "aws_launch_template" "yash_launch_template" {
  name          = "yash-launch-template"
  image_id     = "ami-0866a3c8686eaeeba" # Replace with your AMI ID
  instance_type = "t2.small"
  key_name      = "yashlinux"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Your startup script here
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Step 8: Create a Target Group
resource "aws_lb_target_group" "yash_target_group" {
  name     = "yash-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.yash_vpc.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
  }
}

# Step 9: Create an Application Load Balancer
resource "aws_lb" "yash_application_load_balancer" {
  name               = "yash-application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.yash_allow_http.id]
  subnets            = [aws_subnet.yash_subnet_a.id, aws_subnet.yash_subnet_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "yash-application-load-balancer"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.yash_application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.yash_target_group.arn
  }
}

# Step 10: Create an Auto Scaling Group
resource "aws_autoscaling_group" "yash_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier = [aws_subnet.yash_subnet_a.id, aws_subnet.yash_subnet_b.id]
  launch_template {
    id      = aws_launch_template.yash_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "yash-asg-instance"
    propagate_at_launch = true
  }
}
