# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

# ──────────────────────────────────────────────
# EKS
# ──────────────────────────────────────────────
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_update_kubeconfig" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ──────────────────────────────────────────────
# RDS
# ──────────────────────────────────────────────
output "rds_endpoints" {
  description = "RDS instance endpoints"
  value       = module.rds.endpoints
}

# ──────────────────────────────────────────────
# ElastiCache
# ──────────────────────────────────────────────
output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = module.elasticache.redis_endpoint
}

# ──────────────────────────────────────────────
# SQS
# ──────────────────────────────────────────────
output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = module.sqs.queue_url
}

# ──────────────────────────────────────────────
# ECR
# ──────────────────────────────────────────────
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}
