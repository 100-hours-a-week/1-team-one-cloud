# Cloud Infrastructure

GCP 클라우드 인프라를 Terraform으로 관리하는 IaC(Infrastructure as Code) 프로젝트

## 📁 프로젝트 구조
```
cloud-infra/
├── .gitignore
├── README.md
└── terraform/
    ├── environments/         # 환경별 설정
    │   ├── dev/              # 개발 환경
    │   │   ├── main.tf       # 리소스 정의
    │   │   ├── variables.tf  # 변수 정의
    │   │   ├── providers.tf  # Provider 설정
    │   │   ├── versions.tf   # Terraform/Provider 버전
    │   │   ├── outputs.tf    # 출력 값
    │   │   ├── terraform.tfvars.example  # 변수 값 예시
    │   │   └── .terraform.lock.hcl       # Provider 버전 잠금
    │   └── prod/             # 운영 환경 (예정)
    └── modules/              # 재사용 모듈 (예정)
```

## 관리 중인 인프라 (v1.0)

### GCP 리소스
- **프로젝트**: Raise Developer
- **리전/존**: `us-central1` / `us-central1-c`

### 네트워크
- **VPC**: `default` (자동 모드)
- **서브넷**: 자동 생성 (각 리전별)

### Compute
- **VM 인스턴스**: `raisedeveloper-dev`
  - 머신 타입: `e2-medium`
  - OS: Ubuntu 24.04 LTS
  - 디스크: 32GB (pd-balanced)

### 방화벽
- `default-allow-ssh` (22)
- `default-allow-http` (80)
- `default-allow-https` (443)
- `allow-web-public` (80, 443)

## 로컬 환경

### 1. 사전 준비
```bash
# Terraform 설치 확인
terraform version

# GCP 인증
gcloud auth application-default login

# 프로젝트 설정
gcloud config set project [project-id]
```

### 2. 환경 설정
```bash
cd terraform/environments/dev

# 변수 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 필요시 값 수정
vim terraform.tfvars
```

### 3. Terraform 실행
```bash
# 초기화 (최초 1회 또는 provider 변경 시)
terraform init

# 실행 계획 확인 (변경사항 미리보기)
terraform plan

# 인프라 적용
terraform apply

# 리소스 확인
terraform state list
terraform output
```

## 주요 명령어

### 상태 확인
```bash
# 관리 중인 리소스 목록
terraform state list

# 특정 리소스 상세 정보
terraform state show google_compute_instance.main

# 출력 값 확인
terraform output
terraform output instance_external_ip
```

### 변경 작업
```bash
# 계획 확인 (dry-run)
terraform plan

# 적용
terraform apply

# 특정 리소스만 적용
terraform apply -target=google_compute_firewall.allow_ssh

# 리소스 삭제 (주의!)
terraform destroy
```

## ⚠️ 주의사항

### 민감 정보 관리
- `terraform.tfvars`: 절대 Git에 커밋 금지
- `terraform.tfstate`: 실제 리소스 정보 포함, Git 제외
- `.terraform.lock.hcl`: 버전 관리 위해 반드시 커밋

### 안전한 작업 순서
1. **항상 `terraform plan` 먼저 실행**
2. 변경사항 확인 후 `terraform apply`
3. 중요 작업 전 State 백업

### Lifecycle 관리
- 코드 수정 시 반드시 `plan`으로 영향도 확인
- `destroy` 실행 전 충분한 검토
- VM 재생성(`-/+ replace`) 시 데이터 손실 주의

## 🔄 작업 히스토리

### v1.0 (2025-01-25)
- ✅ 기존 GCP 인프라를 Terraform으로 Import
- ✅ Dev 환경 설정 완료
- ✅ VPC, VM, 방화벽 규칙 코드화

## 📖 참고 자료

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [Google Provider 문서](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)