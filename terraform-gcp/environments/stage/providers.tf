# providers.tf
# Provider(플러그인) 초기화 및 인증 설정

provider "google" {
  project = var.project_id
  region  = var.region
}