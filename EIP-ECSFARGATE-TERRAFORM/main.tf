provider "aws" {
  region = "us-east-1"  # Specify your AWS region
}

# Create a VPC
resource "aws_vpc" "yash_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "yashTerraformVPC"
  }
}

# Create Public Subnet
resource "aws_subnet" "yash_public" {
  vpc_id                  = aws_vpc.yash_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "yashPublicSubnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "yash_private" {
  vpc_id     = aws_vpc.yash_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "yashPrivateSubnet"
  }
}

# Create an Elastic IP
resource "aws_eip" "yash_nat" {
  domain = "vpc"  # Use domain attribute instead of vpc

  tags = {
    Name = "yashTerraformEIP"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "yash_internet_gateway" {
  vpc_id = aws_vpc.yash_vpc.id

  tags = {
    Name = "yashTerraformInternetGateway"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "yash_nat_gateway" {
  allocation_id = aws_eip.yash_nat.id
  subnet_id    = aws_subnet.yash_public.id

  tags = {
    Name = "yashTerraformNATGateway"
  }
}

# Create a Route Table for Public Subnet
resource "aws_route_table" "yash_public" {
  vpc_id = aws_vpc.yash_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yash_internet_gateway.id
  }

  tags = {
    Name = "yashPublicRouteTable"
  }
}

# Associate the Public Route Table with the Public Subnet
resource "aws_route_table_association" "yash_public" {
  subnet_id      = aws_subnet.yash_public.id
  route_table_id = aws_route_table.yash_public.id
}

# Create a Route Table for the Private Subnet
resource "aws_route_table" "yash_private" {
  vpc_id = aws_vpc.yash_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.yash_nat_gateway.id
  }

  tags = {
    Name = "yashPrivateRouteTable"
  }
}

# Associate the Route Table with the Private Subnet
resource "aws_route_table_association" "yash_private" {
  subnet_id      = aws_subnet.yash_private.id
  route_table_id = aws_route_table.yash_private.id
}

# Create a Security Group
resource "aws_security_group" "yash_security_group" {
  vpc_id = aws_vpc.yash_vpc.id
  name   = "yash-security-group"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "yashSecurityGroup"
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "yash_cluster" {
  name = "yash-example-cluster"

  tags = {
    Name = "yashEcsCluster"
  }
}

# Define an ECS Task Definition
resource "aws_ecs_task_definition" "yash_task" {
  family                   = "yash-example-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "yash-example-container"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
      ]
    },
  ])
}

# Create an ECS Service
resource "aws_ecs_service" "yash_service" {
  name            = "yash-example-service"
  cluster         = aws_ecs_cluster.yash_cluster.id
  task_definition = aws_ecs_task_definition.yash_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.yash_private.id]
    security_groups  = [aws_security_group.yash_security_group.id] # Use the created security group
    assign_public_ip = false
  }
}
