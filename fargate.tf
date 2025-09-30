resource "aws_eks_fargate_profile" "demo" {
  cluster_name           = aws_eks_cluster.demo.name
  fargate_profile_name   = "demo-fargate"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod.arn

  subnet_ids = module.network.private_subnet_ids

  selector {
    namespace = "demo"
  }
}

# IAM Role for Fargate pods
resource "aws_iam_role" "eks_fargate_pod" {
  name = "eks-fargate-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_pod_AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_pod.name
}
