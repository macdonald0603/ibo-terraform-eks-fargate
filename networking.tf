# Define the VPC
resource "aws_vpc" "ibo_prod_app" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ibo-prod-app-vpc"
  }
}

# Define Public and Private Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ibo_prod_app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ibo-prod-app-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.ibo_prod_app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "ibo-prod-app-public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.ibo_prod_app.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "ibo-prod-app-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.ibo_prod_app.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "ibo-prod-app-private-subnet-2"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "ibo_prod_app_igw" {
  vpc_id = aws_vpc.ibo_prod_app.id
  tags = {
    Name = "ibo-prod-app-igw"
  }
}

# Public Route Table with route to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ibo_prod_app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ibo_prod_app_igw.id
  }
  tags = {
    Name = "ibo-prod-app-public-rt"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public_subnet_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

####################################
# NAT Gateway & Private Route Table for EKS
####################################

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Create the NAT Gateway in one of your public subnets
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.ibo_prod_app_igw]
}

# Create a Private Route Table for subnets hosting the EKS components
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ibo_prod_app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "ibo-prod-app-private-rt"
  }
}

# Associate the private Route Table with your private subnets
resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}