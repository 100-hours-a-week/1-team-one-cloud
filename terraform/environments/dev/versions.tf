# versions.tf
# Terraform 및 Provider의 버전 요구사항을 명시
# 역할:
#   1. Terraform 자체의 최소 버전 지정
#   2. 사용할 Provider(플러그인)와 버전 지정

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
