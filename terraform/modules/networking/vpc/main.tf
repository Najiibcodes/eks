#vpc + igw
resource "aws_vpc" "eks" {                     
  cidr_block = var.vpc_cidr                   
  tags = {
    Name = "${var.cluster_name}-vpc"         
  }
}

resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

#public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.eks.id
  availability_zone       = var.azs[0]                     
  cidr_block              = var.public_subnet_cidr_a       
  map_public_ip_on_launch = true                           
  tags = {
    Name                                = "public-a"
    "kubernetes.io/role/elb"            = "1"              
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.eks.id
  availability_zone       = var.azs[1]                     
  cidr_block              = var.public_subnet_cidr_b      
  map_public_ip_on_launch = true
  tags = {
    Name                                = "public-b"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

#priv subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.eks.id
  availability_zone = var.azs[0]                           
  cidr_block        = var.private_subnet_cidr_a           
  tags = {
    Name                                = "private-a"
    "kubernetes.io/role/internal-elb"   = "1"              
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.eks.id
  availability_zone = var.azs[1]                           
  cidr_block        = var.private_subnet_cidr_b           
  tags = {
    Name                                = "private-b"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

#nat
resource "aws_eip" "nat" {                                 
  domain = "vpc"
  tags   = { Name = "${var.cluster_name}-nat-eip" }
}

resource "aws_nat_gateway" "eks" {
  allocation_id = aws_eip.nat.id                          
  subnet_id     = aws_subnet.public_a.id                  
  depends_on    = [aws_internet_gateway.eks]               
  tags          = { Name = "${var.cluster_name}-nat" }
}

#route tables
resource "aws_route_table" "public" {                      
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"                              
    gateway_id = aws_internet_gateway.eks.id               
  }
  tags = { Name = "${var.cluster_name}-public-rt" }
}

resource "aws_route_table" "private" {                     
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks.id                
  }
  tags = { Name = "${var.cluster_name}-private-rt" }
}

#rt association
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
