data "aws_vpc" "app_vpc" {
  tags = {
    Name = "app-vpc"
  }
  
}
data "aws_subnets" "app_subnet" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.app_vpc.id]
  }
  tags = {
    Name = "app-subnet-*"
  }
  
}

resource "aws_security_group" "tools_sg" {
  name        = "tools-sg"
  vpc_id      = data.aws_vpc.app_vpc.id

  dynamic "ingress" {
    for_each = [ 22, 8080, 9000, 8081, 9090, 3000, 9100, 9115 ]
    content {
      cidr_blocks    = ["0.0.0.0/0"]
      from_port      = ingress.value
      protocol       = "tcp"
      to_port        = ingress.value

    }
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tools-sg" }
}

resource "aws_instance" "jenkins" {
    ami                           = "ami-035827357e3c7e810"
    instance_type                 = "m7i-flex.large"
    subnet_id                     = data.aws_subnets.app_subnet.ids[0]
    vpc_security_group_ids        = [aws_security_group.tools_sg.id]
    key_name                      = var.ssh_key_name
    associate_public_ip_address   =  true
  
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
    }
    tags = { Name = "jenkins" }
}

resource "aws_instance" "sonarqube" {
    ami                           = "ami-035827357e3c7e810"
    instance_type                 = "m7i-flex.large"
    subnet_id                     = data.aws_subnets.app_subnet.ids[0]
    vpc_security_group_ids        = [aws_security_group.tools_sg.id]
    key_name                      = var.ssh_key_name
    associate_public_ip_address   =  true
  
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
    }
    tags = { Name = "sonarqube" }
}

resource "aws_instance" "nexus" {
    ami                           = "ami-035827357e3c7e810"
    instance_type                 = "m7i-flex.large"
    subnet_id                     = data.aws_subnets.app_subnet.ids[0]
    vpc_security_group_ids        = [aws_security_group.tools_sg.id]
    key_name                      = var.ssh_key_name
    associate_public_ip_address   =  true
  
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
    }
    tags = { Name = "nexus" }
}

resource "aws_instance" "monitor" {
    ami                           = "ami-035827357e3c7e810"
    instance_type                 = "m7i-flex.large"
    subnet_id                     = data.aws_subnets.app_subnet.ids[0]
    vpc_security_group_ids        = [aws_security_group.tools_sg.id]
    key_name                      = var.ssh_key_name
    associate_public_ip_address   =  true
  
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
    }
    tags = { Name = "monitor" }
}
