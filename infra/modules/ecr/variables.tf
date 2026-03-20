variable "project_name" {
  description = "Project name used as prefix for ECR repository names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "services" {
  description = "List of microservice names to create ECR repositories for"
  type        = list(string)
}
