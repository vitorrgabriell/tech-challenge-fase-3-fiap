# ──────────────────────────────────────────────
# Security Group do Cluster
# ──────────────────────────────────────────────
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-eks-cluster-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# EKS Cluster
# Usa LabRole (AWS Academy) — sem criar IAM
# ──────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  version  = var.cluster_version
  role_arn = var.lab_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Name        = "${var.project_name}-eks"
    Environment = var.environment
  }
}

# ──────────────────────────────────────────────
# EKS Node Group
# Também usa LabRole para os workers
# ──────────────────────────────────────────────
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = var.subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.project_name}-workers"
    Environment = var.environment
  }

  depends_on = [aws_eks_cluster.main]
}
