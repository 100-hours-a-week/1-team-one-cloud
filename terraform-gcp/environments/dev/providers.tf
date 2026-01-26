# providers.tf
# Provider(플러그인) 초기화 및 인증 설정
# 역할:
#   1. GCP와 통신하기 위한 설정
#   2. 어떤 프로젝트, 어느 리전에서 작업할지 지정

provider "google" {
  project = var.project_id
  region  = var.region
}
