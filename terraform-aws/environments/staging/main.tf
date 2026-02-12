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

module "s3" {
  source = "../../modules/s3"

  environment        = "staging"
  image_bucket_name  = "raise-developer-staging-bucket"
  deploy_bucket_name = "raise-developer-staging-deploy"

  cors_origins = [
    "https://stage.raisedeveloper.com",
    "http://localhost:3000"
  ]

  tags = {
    Environment = "staging"
    Project     = "raisedeveloper"
    ManagedBy   = "terraform"
  }
}