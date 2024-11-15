# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # Enable auto-assign public IP

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true  # Enable auto-assign public IP

  tags = {
    Name = "subnet-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-rt"
  }
}

resource "aws_route_table_association" "subnet_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.main.id
}

# Security Groups
resource "aws_security_group" "ec2" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

resource "aws_security_group" "efs" {
  name        = "efs-security-group"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }
}

# EFS File System
resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs"
  encrypted      = true

  tags = {
    Name = "MyEFS"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "mount_1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet_1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "mount_2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.subnet_2.id
  security_groups = [aws_security_group.efs.id]
}

# EC2 Instances
# Previous provider and networking configuration remains the same...

# Modified user_data for EC2 instances
resource "aws_instance" "ec2_1" {
  ami           = "ami-012967cc5a8c9f891"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1.id
  key_name      = "yash"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils
              
              # Create mount point
              mkdir -p /efs
              
              # Mount EFS with correct options
              echo "${aws_efs_file_system.efs.dns_name}:/ /efs efs defaults,_netdev,tls 0 0" >> /etc/fstab
              mount -a
              
              # Set correct permissions
              chown ec2-user:ec2-user /efs
              chmod 755 /efs
              
              # Create a test directory with correct permissions
              mkdir -p /efs/shared
              chown ec2-user:ec2-user /efs/shared
              chmod 775 /efs/shared
              
              # Write a test file to verify permissions
              sudo -u ec2-user touch /efs/shared/test.txt
              sudo -u ec2-user echo "Hello from Instance 1" > /efs/shared/test.txt
              EOF

  tags = {
    Name = "EC2-Instance-1"
  }
}

resource "aws_instance" "ec2_2" {
  ami           = "ami-012967cc5a8c9f891"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_2.id
  key_name      = "yash"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-efs-utils
              
              # Create mount point
              mkdir -p /efs
              
              # Mount EFS with correct options
              echo "${aws_efs_file_system.efs.dns_name}:/ /efs efs defaults,_netdev,tls 0 0" >> /etc/fstab
              mount -a
              
              # Set correct permissions
              chown ec2-user:ec2-user /efs
              chmod 755 /efs
              
              # Create a test directory with correct permissions
              mkdir -p /efs/shared
              chown ec2-user:ec2-user /efs/shared
              chmod 775 /efs/shared
              EOF

  tags = {
    Name = "EC2-Instance-2"
  }
}

# Outputs
output "ec2_instance_1_public_ip" {
  value = aws_instance.ec2_1.public_ip
}

output "ec2_instance_2_public_ip" {
  value = aws_instance.ec2_2.public_ip
}

output "efs_dns_name" {
  value = aws_efs_file_system.efs.dns_name
}