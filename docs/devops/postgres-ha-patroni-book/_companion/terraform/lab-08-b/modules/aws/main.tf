# LAB-08-B AWS Module — 3-node Patroni cluster + S3 backup bucket

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region for primary cluster"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Patroni nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "lab-08-b"
}

variable "node_count" {
  description = "Number of Patroni nodes"
  type        = number
  default     = 3
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.cluster_name}-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.cluster_name}-rt"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "patroni" {
  name_prefix = "${var.cluster_name}-sg"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # PostgreSQL
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "PostgreSQL"
  }

  # Patroni REST API
  ingress {
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Patroni REST API"
  }

  # etcd
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "etcd client and peer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instances
resource "aws_instance" "patroni" {
  count                  = var.node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.patroni.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.cluster_name}-node-${count.index + 1}"
    Role = count.index == 0 ? "leader" : "replica"
  }
}

# S3 Backup Bucket
resource "aws_s3_bucket" "backups" {
  bucket_prefix = "${var.cluster_name}-backups-"
  force_destroy = true
  tags = {
    Name = "${var.cluster_name}-backups"
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Suspended"
  }
}

output "instance_ips" {
  description = "Public IPs of Patroni cluster nodes"
  value       = aws_instance.patroni[*].public_ip
}

output "backup_bucket" {
  description = "S3 bucket name for pgBackRest backups"
  value       = aws_s3_bucket.backups.bucket
}
