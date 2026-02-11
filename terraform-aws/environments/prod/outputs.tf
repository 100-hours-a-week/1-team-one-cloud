# environments/production/outputs.tf

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
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