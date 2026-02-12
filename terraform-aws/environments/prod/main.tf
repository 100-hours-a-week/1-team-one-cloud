# environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"

  environment = "production"
  vpc_cidr    = "10.1.0.0/16"
  
  # 가용 영역
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  
  # Public Subnets (ALB)
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  
  # Private Web Subnet (Frontend)
  private_web_subnet_cidr = "10.1.10.0/24"
  
  # Private App Subnet (Backend + AI)
  private_app_subnet_cidr = "10.1.20.0/24"
  
  # Private Data Subnets (RDS + Redis)
  private_data_subnet_cidrs = ["10.1.40.0/24", "10.1.41.0/24"]

  tags = {
    Environment = "production"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}

module "security_groups" {
  source = "../../modules/security_groups"

  environment = "production"
  vpc_id      = module.vpc.vpc_id
  use_rds     = true  # Production은 RDS 사용

  tags = {
    Environment = "production"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  environment = "production"

  tags = {
    Environment = "production"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}

module "parameter_store" {
  source = "../../modules/parameter_store"

  environment = "production"

  server_base_url    = var.server_base_url
  db_host            = var.db_host
  db_password        = var.db_password
  jwt_secret         = var.jwt_secret
  token_hash_secret  = var.token_hash_secret
  ai_server_base_url = var.ai_server_base_url
  gcs_bucket_name    = var.gcs_bucket_name
  gcp_project_id     = var.gcp_project_id
  redis_host         = var.redis_host
  openai_api_key     = var.openai_api_key
  gemini_api_key     = var.gemini_api_key
  ollama_api_key     = var.ollama_api_key

  tags = {
    Environment = "production"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}

module "s3" {
  source = "../../modules/s3"

  environment        = "production"
  image_bucket_name  = "raise-developer-prod-bucket"
  deploy_bucket_name = "raise-developer-prod-deploy"

  cors_origins = [
    "https://raisedeveloper.com",
    "https://www.raisedeveloper.com",
    "http://localhost:3000"
  ]

  tags = {
    Environment = "production"
    Project     = "raisedeveloper"
    ManagedBy   = "terraform"
  }
}