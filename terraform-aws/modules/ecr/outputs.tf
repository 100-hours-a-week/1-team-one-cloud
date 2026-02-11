output "backend_repository_url" {
  description = "Backend ECR Repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "Backend ECR Repository ARN"
  value       = aws_ecr_repository.backend.arn
}

output "backend_repository_name" {
  description = "Backend ECR Repository Name"
  value       = aws_ecr_repository.backend.name
}

output "frontend_repository_url" {
  description = "Frontend ECR Repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_arn" {
  description = "Frontend ECR Repository ARN"
  value       = aws_ecr_repository.frontend.arn
}

output "frontend_repository_name" {
  description = "Frontend ECR Repository Name"
  value       = aws_ecr_repository.frontend.name
}

output "ai_repository_url" {
  description = "AI ECR Repository URL"
  value       = aws_ecr_repository.ai.repository_url
}

output "ai_repository_arn" {
  description = "AI ECR Repository ARN"
  value       = aws_ecr_repository.ai.arn
}

output "ai_repository_name" {
  description = "AI ECR Repository Name"
  value       = aws_ecr_repository.ai.name
}
