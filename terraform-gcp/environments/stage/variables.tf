# GCP 기본 설정
variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "region" {
  description = "GCP 리전"
  type        = string
}

variable "zone" {
  description = "GCP 존"
  type        = string
}

variable "environment" {
  description = "환경 구분"
  type        = string
}

# VM 인스턴스 설정
variable "instance_name" {
  description = "VM 인스턴스 이름"
  type        = string
}

variable "machine_type" {
  description = "머신 타입"
  type        = string
}

variable "boot_disk_size" {
  description = "부트 디스크 크기 (GB)"
  type        = number
}

variable "service_account_email" {
  description = "서비스 계정 이메일 (입력하지 않으면 기본값 사용)"
  type        = string
  default     = null
}

variable "cors_origins" {
  description = "CORS 허용 도메인 목록"
  type        = list(string)
  default     = [
    "http://localhost:3000",
    "https://staging.raisedeveloper.com" # Staging 도메인
  ]
}

variable "boot_disk_image" {
  description = "VM 부트 이미지"
  type        = string
}

variable "boot_disk_type" {
  description = "VM 부트 디스크 타입"
  type        = string
}

variable "ssh_source_ranges" {
  description = "SSH 접속 허용 IP 대역"
  type        = list(string)
}

variable "storage_class" {
  description = "GCS 스토리지 클래스"
  type        = string
}

variable "prod_monitoring_source_ranges" {
  description = "운영(Prod) 모니터링 서버의 소스 IP 대역 (CIDR 형식, 예: [\"IP/32\"])"
  type        = list(string)
  default     = [] # 값이 없으면 방화벽 규칙을 생성하지 않음
}

variable "temp_my_ip" {
  description = "임시 IP (terraform.tfvars 경고 해결용)"
  type        = list(string)
  default     = []
}