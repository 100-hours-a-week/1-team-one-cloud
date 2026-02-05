variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "use_existing_vpc" {
  description = "If true, use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "vpc_name" {
  description = "Name of the existing VPC to use (required if use_existing_vpc is true)"
  type        = string
  default     = ""
}

variable "admin_ip" {
  description = "admin IP"
  type        = list(string)
  default     = []
}