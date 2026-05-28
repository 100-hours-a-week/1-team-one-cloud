# raisedeveloper AWS-Lite Infrastructure (Terraform)

이 디렉토리는 AWS 서울 리전(`ap-northeast-2`)에 단일 EC2 인스턴스 인프라를 프로비저닝하기 위한 IaC(Infrastructure as Code) Terraform 소스 코드입니다. 

비용 효율적인 **단일 인스턴스(Single Instance) 아키텍처**로 구성되어 있습니다.

---

## 🏗️ AWS 인프라 스펙 요약

* **네트워크**: 단일 VPC(`10.0.0.0/16`) 및 단일 퍼블릭 서브넷(`10.0.1.0/24`) 구성.
* **컴퓨팅**: EC2 `t3.small` (2 vCPU, 2 GiB RAM, Ubuntu 22.04 LTS).
* **보안 그룹**: 인바운드 **80 (HTTP)**, **443 (HTTPS)** 포트만 외부 개방. **(SSH 22번 포트 완전 차단)**
* **원격 접속**: AWS Systems Manager(SSM) Session Manager 기반 보안 터널링 접속.
* **볼륨 및 스왑**: **16GB gp3 SSD** 루트 볼륨 설정 및 부팅 시 **4GB Swap Space** 자동 활성화 (총 가용 가상 메모리 6GB 확보로 OOM 사전 예방).
* **S3 버킷**: 기존에 수동 구축된 `raise-developer-production-bucket`을 활용하므로 관련 신규 생성 리소스는 주석 격리 처리됨 (EC2의 S3 IAM 권한 매핑만 활성화 유지).

---

## 🚀 배포 순서 및 명령어

### 0단계. AWS CLI 및 자격 증명(Credentials) 설정
테라폼이 AWS 리소스를 안전하게 생성할 수 있도록 로컬 컴퓨터에 AWS 권한을 연동해야 합니다.

1. **AWS CLI 설치**: 터미널에서 `aws --version`을 실행해 AWS CLI 설치 여부를 확인합니다. (미설치 시 공식 문서를 참조해 설치 진행)
2. **AWS 자격 증명(Credentials) 설정**: 아래 명령어를 실행하여 프로비저닝 권한을 가진 IAM 사용자의 액세스 키를 등록합니다.
   ```bash
   aws configure
   ```
   * **AWS Access Key ID**: 발급받은 IAM 액세스 키 입력
   * **AWS Secret Access Key**: 발급받은 IAM 비밀 액세스 키 입력
   * **Default region name**: `ap-northeast-2`
   * **Default output format**: `json`

   혹은 아래 명령어로 임시로 권한을 사용할 수 있다.
   ```bash
   aws login
   ```

### 1단계. 테라폼 초기화 (Init)
필요한 AWS 프로바이더 플러그인을 다운로드합니다.
```bash
terraform init
```

### 2단계. 배포 계획 검토 (Plan)
인프라가 어떻게 생성되는지 사전에 검토합니다.
```bash
terraform plan
```

### 3단계. 인프라 배포 적용 (Apply)
실제 AWS 상에 리소스를 프로비저닝합니다. (확인 질문 시 `yes` 입력)
```bash
terraform apply
```

---

## 🔑 배포 후 EC2 접속 가이드

인프라가 배포되면 테라폼 아웃풋(Outputs)으로 EC2 인스턴스 ID와 원격 접속 명령어가 출력됩니다. SSH 키 페어 없이 아래 AWS CLI 명령어로 안전하게 서버 터널 쉘에 진입합니다:

```bash
# AWS SSM Session Manager를 통한 접속
aws ssm start-session --target <출력된_EC2_인스턴스_ID>
```

터미널 진입 후 가상 메모리가 정상 셋업되었는지 확인하는 명령어:
```bash
free -m
# Swap 영역에 4096MB가 할당되어 있는지 점검합니다.
```
