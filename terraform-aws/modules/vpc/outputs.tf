# modules/vpc/outputs.tf

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_web_subnet_id" {
  description = "Private Web subnet ID"
  value       = aws_subnet.private_web.id
}

output "private_app_subnet_id" {
  description = "Private App subnet ID"
  value       = aws_subnet.private_app.id
}

output "private_data_subnet_ids" {
  description = "Private Data subnet IDs"
  value       = aws_subnet.private_data[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table ID (Main RT)"
  value       = aws_default_route_table.private.id  
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  description = "Frontend Security Group ID"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "Backend Security Group ID"
  value       = aws_security_group.backend.id
}

output "ai_security_group_id" {
  description = "AI Security Group ID"
  value       = aws_security_group.ai.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}