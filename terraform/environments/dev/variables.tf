# variables.tf
# 입력 변수 선언만 하는 파일 (실제 값은 terraform.tfvars에)
# 역할:
#   1. 어떤 변수를 받을지 정의
#   2. 타입 검증 (string, number 등)
#   3. 기본값 설정 (optional)
# 사용: main.tf에서 var.변수명으로 참조

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
