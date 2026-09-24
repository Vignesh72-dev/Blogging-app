output "cluster_id" { value = aws_eks_cluster.main.id }
output "node_group_id" { value = aws_eks_node_group.main.id}
output "vpc_id"        { value = data.aws_vpc.app_vpc.id }
output "subnet_ids"    { value = data.aws_subnets.app_subnet.ids }