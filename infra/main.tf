# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ──────────────────────────────────────────────
# EKS Cluster
# ──────────────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_version    = var.eks_cluster_version
  lab_role_arn       = data.aws_iam_role.lab_role.arn
  subnet_ids         = module.networking.private_subnet_ids
  vpc_id             = module.networking.vpc_id
  node_instance_type = var.eks_node_instance_type
  node_desired       = var.eks_node_desired
  node_min           = var.eks_node_min
  node_max           = var.eks_node_max
}

# ──────────────────────────────────────────────
# RDS — 3 instâncias PostgreSQL
# (auth, flag, targeting)
# ──────────────────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name    = var.project_name
  environment     = var.environment
  db_names        = ["auth", "flag", "targeting"]
  instance_class  = var.db_instance_class
  username        = var.db_username
  password        = var.db_password
  subnet_ids      = module.networking.private_subnet_ids
  vpc_id          = module.networking.vpc_id
  allowed_sg_id   = module.eks.cluster_security_group_id
}

# ──────────────────────────────────────────────
# ElastiCache — Redis
# ──────────────────────────────────────────────
module "elasticache" {
  source = "./modules/elasticache"

  project_name  = var.project_name
  environment   = var.environment
  node_type     = var.redis_node_type
  subnet_ids    = module.networking.private_subnet_ids
  vpc_id        = module.networking.vpc_id
  allowed_sg_id = module.eks.cluster_security_group_id
}

# ──────────────────────────────────────────────
# DynamoDB — ToggleMasterAnalytics
# ──────────────────────────────────────────────
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

# ──────────────────────────────────────────────
# SQS — Fila de eventos
# ──────────────────────────────────────────────
module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  environment  = var.environment
}

# ──────────────────────────────────────────────
# ECR — 5 repositórios de imagens
# ──────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  services     = var.services
}
