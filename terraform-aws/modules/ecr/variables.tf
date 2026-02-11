# modules/ecr/variables.tf
variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}