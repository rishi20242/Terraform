```hcl
#############################
# 🌍 PROVIDER CONFIGURATION
#############################
provider "aws" {
  region = "us-east-1"  # Change as needed
}

#############################
# 🏗️ VPC
#############################
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  # Enable DNS for EC2, ALB, etc.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sample-vpc"
  }
}

#############################
# 🌐 SUBNETS
#############################

# Public Subnet (Internet-facing)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Auto-assign public IP

  tags = {
    Name = "public-subnet-1"
  }
}

# Private Subnet (Internal use)
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet-1"
  }
}

#############################
# 🌍 INTERNET GATEWAY
#############################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw-1"
  }
}

#############################
# 🛣️ ROUTE TABLE (PUBLIC)
#############################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  # Route all traffic to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table-1"
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#############################
# 🔐 SECURITY GROUP
#############################
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Allow SSH access (restrict in real-world)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-security-group"
  }
}

#############################
# 💻 EC2 INSTANCE (MODULE)
#############################
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name           = "first-instance"
  instance_type  = "t3.micro"
  key_name       = "batman_n_virgnina"
  monitoring     = true

  # Attach instance to public subnet
  subnet_id = aws_subnet.public_subnet.id

  # Attach security group
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```
