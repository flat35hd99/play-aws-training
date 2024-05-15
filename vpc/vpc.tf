terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.8.3"
}

provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.lab.id
  cidr_block = "10.0.0.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name = "Public subnet"
  }
}

resource "aws_internet_gateway" "lab_IGW" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_IGW.id
  }
}

resource "aws_route_table_association" "public_route_table" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

# private -> public -> internet
# するためのNGWと、NGWのインターネット側に出すGlobal IP
resource "aws_eip" "lab_ngw" {
}

resource "aws_nat_gateway" "lab_ngw" {
  allocation_id = aws_eip.lab_ngw.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.lab_IGW]
}

# Publicのセキュリティグループとルール
resource "aws_security_group" "lab_public" {
  name        = "Public SG"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_ingress_rule" "public_HTTP" {
  security_group_id = aws_security_group.lab_public.id

  // HTTP
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  to_port     = 80
  from_port   = 80
}

// Privateサブネット
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.lab.id
  cidr_block = "10.0.2.0/23"

  tags = {
    Name = "Private subnet"
  }
}

resource "aws_security_group" "lab_private" {
  vpc_id      = aws_vpc.lab.id
  name        = "Private SG"
  description = "Allow HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "private_HTTP" {
  security_group_id = aws_security_group.lab_private.id

  ip_protocol                  = "tcp"
  to_port                      = 80
  from_port                    = 80
  referenced_security_group_id = aws_security_group.lab_public.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_ngw.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private_route_table" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_route_table.id
}
