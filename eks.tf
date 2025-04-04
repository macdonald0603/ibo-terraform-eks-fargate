####################################
# IAM Roles and Policies for EKS
####################################

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "ibo-prod-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node
resource "aws_iam_role" "eks_node_role" {
  name = "ibo-prod-eks-node-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for EKS Fargate Profile (if you need Fargate)
resource "aws_iam_role" "eks_fargate_execution_role" {
  name = "ibo-prod-eks-fargate-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_execution_role_policy" {
  role       = aws_iam_role.eks_fargate_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

####################################
# EKS Cluster, Node Group, and Fargate Profile
####################################

# Create the EKS Cluster using the existing private subnets
resource "aws_eks_cluster" "ibo_prod_eks" {
  name     = "ibo-prod-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
    endpoint_public_access  = true
    endpoint_private_access = true
  }
}

# EKS Node Group (running in private subnets)
resource "aws_eks_node_group" "ibo_prod_node_group" {
  cluster_name    = aws_eks_cluster.ibo_prod_eks.name
  node_group_name = "ibo-prod-eks-node-grp1"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}

# (Optional) EKS Fargate Profile if you plan to run Fargate workloads
resource "aws_eks_fargate_profile" "ibo_fargate" {
  cluster_name           = aws_eks_cluster.ibo_prod_eks.name
  fargate_profile_name   = "ibo-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_execution_role.arn
  subnet_ids             = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  selector {
    namespace = "default"
  }
}

####################################
# Data Sources and Provider for Kubernetes
####################################

# Retrieve EKS cluster authentication data
data "aws_eks_cluster_auth" "ibo_prod_eks" {
  name = aws_eks_cluster.ibo_prod_eks.name
}