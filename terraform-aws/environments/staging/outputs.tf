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
