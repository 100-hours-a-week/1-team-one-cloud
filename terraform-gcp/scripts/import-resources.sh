#!/bin/bash
# import.sh
# 역할: 기존 GCP 리소스를 Terraform state에 등록
# 사용 시점: Terraform으로 관리 전에 이미 생성된 리소스가 있을 때
# 주의: 이미 import된 리소스는 다시 실행 시 에러 발생
# 현재는 terraform.tfstate에 모든 리소스가 등록되어 있어 재실행 불필요
set -e

PROJECT_ID="your-project-id"
REGION="us-central1"
ZONE="us-central1-c"

echo "기존 GCP 리소스를 Terraform으로 Import 시작"

# 1. Default VPC
echo "VPC 네트워크 import"
terraform import google_compute_network.default ${PROJECT_ID}/default

# 2. VM 인스턴스
echo "VM 인스턴스 import"
terraform import google_compute_instance.main projects/${PROJECT_ID}/zones/${ZONE}/instances/raisedeveloper-dev

# 3. 방화벽 규칙들
echo "방화벽 규칙 import"
terraform import google_compute_firewall.allow_ssh ${PROJECT_ID}/default-allow-ssh
terraform import google_compute_firewall.allow_http ${PROJECT_ID}/default-allow-http
terraform import google_compute_firewall.allow_https ${PROJECT_ID}/default-allow-https
terraform import google_compute_firewall.allow_web_public ${PROJECT_ID}/allow-web-public

echo "Import 완료!"
