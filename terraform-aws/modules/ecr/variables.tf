# modules/ecr/variables.tf
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}