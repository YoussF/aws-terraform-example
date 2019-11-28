###### VARIABLES DEFINITION
########################################################################
# AMI IMAGE
variable "ami" {
default = "ami-045fa58af83eb0ff4"
}

# VPC Network
variable "vpc_cidr" {
default = "192.168.0.0/16"
}

# NETWORK PARAMS
variable "network_http" {
default = {
    subnet_name = "subnet_http"
    cidr        = "192.168.1.0/24"
}
}
###### END VARIABLES DEFINITION
########################################################################



###### PROVIDER DEFINITION
provider "aws" {
    profile =   "default"
    region  =   "eu-west-3"
}
###### END PROVIDER DEFINITION
########################################################################



###### VPC DEFINITION
resource "aws_vpc" "hello_vpc2" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "hello_vpc2"
  }
}
###### END VPC DEFINITION
########################################################################



###### IGW DEFINITION
########################################################################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.hello_vpc2.id
  tags = {
    Name = "internet-gateway"
  }
}
###### END IGW DEFINITION
########################################################################



###### SUBNET DEFINITION
########################################################################
resource "aws_subnet" "http" {
  vpc_id     = aws_vpc.hello_vpc2.id
  cidr_block = var.network_http["cidr"]
  tags = {
    Name = "subnet-http"
  }
  depends_on = [aws_internet_gateway.gw]
}
###### END SUBNET DEFINITION
########################################################################



###### ROUTES DEFINITION
########################################################################
resource "aws_route_table" "custom-route-table" {
  vpc_id = aws_vpc.hello_vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "custom route table"
  }
}
resource "aws_route_table_association" "http-association" {
  subnet_id      = aws_subnet.http.id
  route_table_id = aws_route_table.custom-route-table.id
}
###### END ROUTES DEFINITION
########################################################################



###### NACL DEFINITION (SECURITY RULES)
########################################################################
###### END NACL DEFINITION (SECURITY RULES)
########################################################################



###### SECUIRTY GROUP DEFINITION
########################################################################
resource "aws_security_group" "administration" {
  name        = "administration"
  description = "Allow default administration service"
  vpc_id      = aws_vpc.hello_vpc2.id
  tags = {
    Name = "administration"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Open web port
resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow web incgress trafic"
  vpc_id      = aws_vpc.hello_vpc2.id
  tags = {
    Name = "web"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
###### END SECURITY DEFINITION
########################################################################



###### KEY PAIR DEFINITION
########################################################################
resource "aws_key_pair" "user_key" {
  key_name   = "user-key"
  public_key = ""
}
###### END KEY PAIR DEFINITION
########################################################################



###### INSTANCES DEFINITION
########################################################################
resource "aws_instance" "http" {
  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = aws_key_pair.user_key.key_name
  vpc_security_group_ids = [
    aws_security_group.administration.id,
    aws_security_group.web.id,
  ]
  subnet_id = aws_subnet.http.id
  //user_data = file("scripts/first-boot.sh")
  tags = {
    Name = "http-instance"
  }
}


resource "aws_eip" "public_http" {
  vpc        = true
  instance   = aws_instance.http.id
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "public-http"
  }
}
###### END INSTANCES DEFINITION
########################################################################
