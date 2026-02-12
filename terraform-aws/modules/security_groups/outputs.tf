# modules/security_groups/outputs.tf

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "frontend_sg_id" {
  description = "Frontend Security Group ID"
  value       = aws_security_group.frontend.id
}

output "backend_sg_id" {
  description = "Backend Security Group ID"
  value       = aws_security_group.backend.id
}

output "ai_sg_id" {
  description = "AI Security Group ID"
  value       = aws_security_group.ai.id
}

output "mysql_instance_sg_id" {
  description = "MySQL Instance Security Group ID (Staging)"
  value       = var.use_rds ? null : aws_security_group.mysql_instance[0].id
}

output "redis_instance_sg_id" {
  description = "Redis Instance Security Group ID"
  value       = aws_security_group.redis_instance.id
}

output "rds_sg_id" {
  description = "RDS Security Group ID (Production)"
  value       = var.use_rds ? aws_security_group.rds[0].id : null
}