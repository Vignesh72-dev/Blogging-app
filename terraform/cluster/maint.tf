data "aws_vpc" "app_vpc" {
  tags = {
    Name = "app-vpc"
  }
  
}
data "aws_internet_gateway" "app_igw" {
  tags = {
    Name = "app-igw"
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

resource "aws_route_table" "app_rt" {
  vpc_id = data.aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "app-rt"
  }
}

resource "aws_route_table_association" "a" {
  count = 2
  subnet_id      = data.aws_subnets.app_subnet.ids[count.index]
  route_table_id = aws_route_table.app_rt.id
}

resource "aws_security_group" "cluster_sg" {
  vpc_id = data.aws_vpc.app_vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = { Name = "cluster-sg"}
}

resource "aws_security_group" "node_sg" {
  vpc_id = data.aws_vpc.app_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "node-sg" }
}

#cluster details
resource "aws_eks_cluster" "main" {
  name = "app-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.app_subnet.ids
    security_group_ids = [aws_security_group.cluster_sg.id]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

resource "aws_iam_role" "cluster_role" {
  name = "app-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

#node details

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "app-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = data.aws_subnets.app_subnet.ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  instance_types = ["m7i-flex.large"]
  remote_access {
    ec2_ssh_key        = var.ssh_key_name
    source_security_group_ids = [ aws_security_group.node_sg.id ]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "node_group_role" {
  name = "app-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}


