# environments/production/outputs.tf

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_sg_id" {
  description = "Production ALB Security Group ID"
  value       = module.security_groups.alb_sg_id
}

output "frontend_sg_id" {
  description = "Production Frontend Security Group ID"
  value       = module.security_groups.frontend_sg_id
}

output "backend_sg_id" {
  description = "Production Backend Security Group ID"
  value       = module.security_groups.backend_sg_id
}

output "ai_sg_id" {
  description = "Production AI Security Group ID"
  value       = module.security_groups.ai_sg_id
}

output "rds_sg_id" {
  description = "Production RDS Security Group ID"
  value       = module.security_groups.rds_sg_id
}

output "redis_instance_sg_id" {
  description = "Production Redis Instance Security Group ID"
  value       = module.security_groups.redis_instance_sg_id
}

output "ecr_backend_url" {
  description = "Backend ECR Repository URL"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  description = "Frontend ECR Repository URL"
  value       = module.ecr.frontend_repository_url
}

output "ecr_ai_url" {
  description = "AI ECR Repository URL"
  value       = module.ecr.ai_repository_url
}