# modules/s3/variables.tf

variable "environment" {
  description = "Environment name (production, staging)"
  type        = string
}

variable "image_bucket_name" {
  description = "이미지 저장용 S3 버킷 이름 (GCS 대체)"
  type        = string
}

variable "deploy_bucket_name" {
  description = "배포용 S3 버킷 이름 (docker-compose, secrets)"
  type        = string
}

variable "cors_origins" {
  description = "CORS 허용 Origin 목록"
  type        = list(string)
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}