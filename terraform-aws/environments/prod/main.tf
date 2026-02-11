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