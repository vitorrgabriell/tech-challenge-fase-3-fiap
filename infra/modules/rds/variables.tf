variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_names" {
  description = "List of database names (auth, flag, targeting)"
  type        = list(string)
}

variable "instance_class" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_sg_id" {
  description = "Security Group ID allowed to access RDS"
  type        = string
}
