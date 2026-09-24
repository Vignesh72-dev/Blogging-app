provider "aws" {
    region = "ap-south-1"
  
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { 
    Name = "app-vpc"
  }
}

resource "aws_subnet" "app_subnet" {
    count                              = 2
    vpc_id                             = aws_vpc.app_vpc.id
    cidr_block                         = cidrsubnet(aws_vpc.app_vpc.cidr_block, 8, count.index)
    availability_zone                  = element(["ap-south-1a", "ap-south-1b"], count.index)
    map_public_ip_on_launch            = true
    tags = { Name = "app-subnet-${count.index}"} 
  
}

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "app-igw"
  }
}

resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "app-rt"
  }
  
}

resource "aws_route_table_association" "app_rta" {
  count          = 2
  subnet_id      = aws_subnet.app_subnet[count.index].id
  route_table_id = aws_route_table.app_rt.id
}