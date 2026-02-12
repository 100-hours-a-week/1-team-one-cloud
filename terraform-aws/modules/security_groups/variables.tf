# modules/security_groups/variables.tf

variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "use_rds" {
  description = "Use RDS MySQL (true for production, false for staging)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}