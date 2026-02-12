module "ecr" {
  source = "../../modules/ecr"

  environment = "staging"

  tags = {
    Environment = "staging"
    Project     = "RaiseDeveloper"
    ManagedBy   = "Terraform"
  }
}