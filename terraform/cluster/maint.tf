provider "aws" {
  region = "ap-south-1"
}

# ---------- Existing network (created by the VPC config) ----------

data "aws_vpc" "app_vpc" {
  tags = {
    Name = "app-vpc"
  }
}

data "aws_subnets" "app_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["app-subnet-*"]
  }
}

# ---------- Cluster ----------

resource "aws_security_group" "cluster_sg" {
  name   = "app-cluster-sg"
  vpc_id = data.aws_vpc.app_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "cluster-sg" }
}

resource "aws_iam_role" "cluster_role" {
  name = "app-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_eks_cluster" "main" {
  name     = "app-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids         = data.aws_subnets.app_subnet.ids
    security_group_ids = [aws_security_group.cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

# ---------- Nodes ----------

resource "aws_iam_role" "node_group_role" {
  name = "app-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
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

# Optional: shell access to nodes via SSM Session Manager (no SSH needed)
resource "aws_iam_role_policy_attachment" "node-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "app-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = data.aws_subnets.app_subnet.ids
  instance_types  = ["m7i-flex.large"]

  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-AmazonSSMManagedInstanceCore,
  ]
}