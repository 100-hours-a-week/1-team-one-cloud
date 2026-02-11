# modules/vpc/variables.tf
variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
  
  # 허용된 환경만
  validation {
    condition     = contains(["production", "staging", "dev"], var.environment)
    error_message = "environment must be production, staging, or dev" 
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  
  # CIDR 형식 검증
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.1.0.0/16)"
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required for ALB and RDS"
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (for ALB)"
  type        = list(string)
  
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnets required for ALB"
  }
}

variable "private_web_subnet_cidr" {
  description = "Private Web tier subnet CIDR (Frontend)"
  type        = string
}

variable "private_app_subnet_cidr" {
  description = "Private App tier subnet CIDR (Backend + AI)"
  type        = string
}

variable "private_data_subnet_cidrs" {
  description = "Private Data tier subnet CIDR blocks (RDS + Redis)"
  type        = list(string)
  
  validation {
    condition     = length(var.private_data_subnet_cidrs) == 2
    error_message = "Exactly 2 data subnets required for RDS Subnet Group"
  }
}