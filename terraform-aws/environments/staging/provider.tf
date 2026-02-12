# environments/staging/provider.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
  
  default_tags {
    tags = {
      Environment = "staging"
      Project     = "RaiseDeveloper"
    }
  }
}
