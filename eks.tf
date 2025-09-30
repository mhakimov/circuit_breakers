resource "aws_eks_cluster" "demo" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = module.network.private_subnet_ids
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}


# resource "aws_eks_node_group" "demo_nodes" {
#   cluster_name    = aws_eks_cluster.demo.name
#   node_group_name = "demo-nodes"
#   node_role_arn   = aws_iam_role.eks_nodes.arn
#   subnet_ids      = module.network.private_subnet_ids

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   remote_access {
#     # ec2_ssh_key            = var.key_name
#     source_security_group_ids = [aws_security_group.eks_nodes.id]
#   }

#   instance_types = ["t3.micro"]
#   ami_type       = "AL2_x86_64"
#   depends_on     = [aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy]
# }

resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = module.network.vpc_id

  # Allow worker nodes to talk to control plane
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# resource "aws_security_group" "eks_nodes" {
#   name        = "eks-nodes-sg"
#   description = "Worker node SG"
#   vpc_id      = module.network.vpc_id

#   # Allow worker nodes to communicate with control plane
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.eks_cluster.id]
#   }

#   # Allow all node-to-node traffic
#   ingress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     self      = true
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-nodes-sg"
#   }
# }

