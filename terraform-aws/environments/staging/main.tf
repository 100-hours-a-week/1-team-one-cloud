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

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Tier = "Public"
  }
}

module "alb" {
  source = "../../modules/alb"

  environment           = "staging"
  vpc_id                = data.aws_vpc.shared.id
  public_subnet_ids     = data.aws_subnets.public.ids
  alb_security_group_id = module.security_groups.alb_sg_id

  tags = {
    Environment = "staging"
    Project     = "RaiseDeveloper"
    ManagedBy   = "terraform"
  }
}
