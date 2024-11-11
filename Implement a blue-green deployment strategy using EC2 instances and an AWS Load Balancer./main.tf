provider "aws" {
  region = "us-east-1"
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "blue-green-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "blue-green-igw"
  }
}

# Create two subnets in different AZs
resource "aws_subnet" "blue" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "blue-subnet"
  }
}

resource "aws_subnet" "green" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "green-subnet"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "blue-green-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "blue" {
  subnet_id      = aws_subnet.blue.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "green" {
  subnet_id      = aws_subnet.green.id
  route_table_id = aws_route_table.main.id
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "instance" {
  name        = "instance-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# EC2 Instances
resource "aws_instance" "blue" {
  ami                    = "ami-063d43db0594b521b"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.blue.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = "yash"
  
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Blue Environment</h1>" > /var/www/html/index.html
              EOF
  
  tags = {
    Name        = "blue-instance"
    Environment = "blue"
  }
}

resource "aws_instance" "green" {
  ami                    = "ami-063d43db0594b521b"  # Same AMI as blue
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.green.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = "yash"
  
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Green Environment</h1>" > /var/www/html/index.html
              EOF
  
  tags = {
    Name        = "green-instance"
    Environment = "green"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "blue-green-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = [aws_subnet.blue.id, aws_subnet.green.id]

  tags = {
    Name = "blue-green-alb"
  }
}

# ALB Target Groups
resource "aws_lb_target_group" "blue" {
  name                 = "blue-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "blue-tg"
  }
}

resource "aws_lb_target_group" "green" {
  name                 = "green-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "green-tg"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.green.id
  port             = 80
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn  # Default to blue environment
  }
}

# Output values
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "listener_arn" {
  value = aws_lb_listener.front_end.arn
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "blue_instance_ip" {
  value = aws_instance.blue.public_ip
}

output "green_instance_ip" {
  value = aws_instance.green.public_ip
}