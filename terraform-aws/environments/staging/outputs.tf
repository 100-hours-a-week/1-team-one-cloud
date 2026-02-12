# environments/staging/outputs.tf

# Security Group Outputs 
output "alb_sg_id" {
  description = "Staging ALB Security Group ID"
  value       = module.security_groups.alb_sg_id
}

output "frontend_sg_id" {
  description = "Staging Frontend Security Group ID"
  value       = module.security_groups.frontend_sg_id
}

output "backend_sg_id" {
  description = "Staging Backend Security Group ID"
  value       = module.security_groups.backend_sg_id
}

output "ai_sg_id" {
  description = "Staging AI Security Group ID"
  value       = module.security_groups.ai_sg_id
}

output "mysql_instance_sg_id" {
  description = "Staging MySQL Instance Security Group ID"
  value       = module.security_groups.mysql_instance_sg_id
}

output "redis_instance_sg_id" {
  description = "Staging Redis Instance Security Group ID"
  value       = module.security_groups.redis_instance_sg_id
}

# ECR Outputs 
output "ecr_backend_url" {
  description = "Staging Backend ECR URL"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  description = "Staging Frontend ECR URL"
  value       = module.ecr.frontend_repository_url
}

output "ecr_ai_url" {
  description = "Staging AI ECR URL"
  value       = module.ecr.ai_repository_url
}