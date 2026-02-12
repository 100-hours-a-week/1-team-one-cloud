# environments/staging/main.tf

# VPC 참조 (Production VPC 공유)
data "aws_vpc" "shared" {
  tags = {
    Name = "production-vpc"
  }
}

module "security_groups" {
  source = "../../modules/security_groups"

  environment = "staging"
  vpc_id      = data.aws_vpc.shared.id
  use_rds     = false  # Staging은 MySQL 컨테이너 사용

  tags = {
    Environment = "staging"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  environment = "staging"

  tags = {
    Environment = "staging"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}