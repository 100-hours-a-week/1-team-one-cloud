# environments/production/outputs.tf

output "vpc_id" {
  description = "Production VPC ID"
  value       = module.vpc.vpc_id
}