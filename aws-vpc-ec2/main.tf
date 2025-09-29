provider "aws" {
  region = "ap-south-1"
}

# -------------------- VPC --------------------
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "Demo VPC - Brew-Labs"
  }
}

# -------------------- AZs --------------------
data "aws_availability_zones" "all" {}

# -------------------- Public Subnet --------------------
resource "aws_subnet" "public_ap_south_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet1_cidr
  availability_zone = data.aws_availability_zones.all.names[0]

  tags = {
    Name = "Public Subnet - Brew-Labs"
  }
}

# -------------------- IGW --------------------
resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Demo IGW - Brew-Labs"
  }
}

# -------------------- Public Route Table --------------------
resource "aws_route_table" "my_vpc_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_vpc_igw.id
  }

  tags = {
    Name = "Demo Public RT - Brew-Labs"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_ap_south_1a.id
  route_table_id = aws_route_table.my_vpc_public.id
}

# -------------------- Elastic IP for NAT --------------------
resource "aws_eip" "nat" {
  domain = "vpc"
}

# -------------------- NAT Gateway --------------------
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_ap_south_1a.id

  tags = {
    Name = "Demo NAT GW - Brew-Labs"
  }

  depends_on = [aws_internet_gateway.my_vpc_igw]
}

# -------------------- Private Subnet --------------------
resource "aws_subnet" "private_ap_south_1b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet2_cidr
  availability_zone = data.aws_availability_zones.all.names[1]

  tags = {
    Name = "Private Subnet - Brew-Labs"
  }
}

# -------------------- Private Route Table --------------------
resource "aws_route_table" "my_vpc_private" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Demo Private RT - Brew-Labs"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_ap_south_1b.id
  route_table_id = aws_route_table.my_vpc_private.id
}

# -------------------- Security Group --------------------
resource "aws_security_group" "instance" {
  name   = "brew-example-instance"
  vpc_id = aws_vpc.my_vpc.id

  # allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound for webserver
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG - Brew-Labs"
  }
}

# -------------------- EC2 Instance --------------------
resource "aws_instance" "server" {
  ami                    = var.amiid
  instance_type          = var.type
  key_name               = var.pemfile
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.public_ap_south_1a.id
  availability_zone      = data.aws_availability_zones.all.names[0]

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    # Create a simple HTML file
    cat <<EOT > index.html
    <html>
      <body>
        <h1 style="font-size:50px;color:blue;">Brew Labs "Asif"</h1>
      </body>
    </html>
    EOT

    # Start a lightweight HTTP server with busybox on port 8080
    nohup busybox httpd -f -p 8080 &
  EOF

  tags = {
    Name = "Web Server - Brew-Labs"
  }
}
