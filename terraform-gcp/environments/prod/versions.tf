terraform {
  required_version = ">= 1.0"

  # GCP를 제어하기 위한 플러그인
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}