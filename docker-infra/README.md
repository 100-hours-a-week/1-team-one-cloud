# 🐳 raisedeveloper 프로덕션 단일 인스턴스 빌드 & 배포 가이드 (Docker Compose)

이 가이드는 단일 EC2 인스턴스 환경에서 **각 서비스 레포지토리(FE, BE, AI)를 직접 Git Clone하고, 인스턴스 내부에서 Docker 이미지를 빌드하여 Docker Compose로 일괄 배포 및 운영**하는 최적의 배포 절차를 설명합니다.

외부 이미지 레지스트리(ECR 등)나 별도의 CI/CD 서버 없이, 단일 서버 내에서 빌드와 배포를 모두 완결하는 가볍고 직관적인 구조입니다.

---

## 📁 파일 구조 설계 (EC2 인스턴스 내부)

단일 인스턴스 내에서 모든 서비스가 원활히 빌드되고 도커 컴포즈가 정상적으로 참조할 수 있도록, 동일한 부모 디렉토리(예: `~/` 또는 `/home/ubuntu/`) 아래에 모든 레포지토리를 동일한 계층 구조로 클론합니다.

```text
/home/ubuntu/                             # 사용자 홈 디렉토리
├── 1-team-one-fe/                        # 프론트엔드 레포지토리 (Next.js)
│   └── Dockerfile
├── 1-team-one-be/                        # 백엔드 레포지토리 (Spring Boot)
│   └── Dockerfile
├── 1-team-one-ai/                        # AI 서비스 레포지토리 (FastAPI)
│   └── Dockerfile
└── 1-team-one-cloud/                     # 클라우드/인프라 레포지토리
    └── docker-infra/                     # 📌 배포 작업 디렉토리
        ├── docker-compose.prod.yml       # 프로덕션 Docker Compose 설정
        ├── nginx.prod.conf               # 프로덕션 Nginx 프록시 설정
        ├── .env.prod                     # 프로덕션 환경 변수 템플릿
        └── README.md                     # 본 가이드 파일
```

---

## 🛠️ [1단계] 인스턴스 사전 준비 및 Git Clone

EC2 인스턴스에 접속하여 빌드 및 배포에 필요한 패키지를 설치하고, 소스 코드를 복제합니다.

### 1. 필수 의존성 패키지 설치
서버에 Docker, Docker Compose, Git이 설치되어 있어야 합니다. (Ubuntu 기준)
```bash
# 패키지 업데이트
sudo apt-get update -y

# Git 및 Docker 설치
sudo apt-get install -y git docker.io

# Docker Compose V2 설치 (최신 버전 권장)
sudo mkdir -p /usr/local/lib/docker/cli-plugins/
sudo curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 현재 유저를 docker 그룹에 추가하여 sudo 없이 실행 가능하도록 설정 (재로그인 필요)
sudo usermod -aG docker $USER
```

### 2. 서비스 레포지토리 복제 (Git Clone)
홈 디렉토리(`~/`)로 이동하여 프론트엔드, 백엔드, AI, 클라우드 레포지토리를 각각 클론합니다.
```bash
cd ~/

# 1. 프론트엔드 복제
git clone https://github.com/your-organization/1-team-one-fe.git

# 2. 백엔드 복제
git clone https://github.com/your-organization/1-team-one-be.git

# 3. AI 서비스 복제
git clone https://github.com/your-organization/1-team-one-ai.git

# 4. 클라우드 인프라 복제
git clone https://github.com/your-organization/1-team-one-cloud.git
```
> [!NOTE]
> 실제 깃허브 레포지토리 URL로 치환하여 실행해 주세요. 비공개 레포지토리인 경우 Personal Access Token(PAT) 또는 SSH Key 등록이 필요할 수 있습니다.

---

## ⚠️ [2단계] 호스트 OS 사전 설정 (비밀 키 배치)

### 1. 외부 비밀 키 (Firebase Service Account Key) 배치
백엔드(`backend`) 서비스 컨테이너는 민감 정보 보호를 위해 **호스트 OS의 특정 경로를 직접 바인드 마운트**하여 구동됩니다.
```yaml
    volumes:
      - /etc/secrets:/etc/secrets:ro
```
인스턴스 내부의 아래 경로에 Firebase 키 파일을 **반드시 사전에 수동으로 배치**해야 합니다.
```bash
sudo mkdir -p /etc/secrets
# 외부에서 다운로드받은 firebase-key.json 파일을 해당 위치로 업로드 및 복사합니다.
sudo cp path/to/your/firebase-key.json /etc/secrets/firebase-key.json
# 읽기 권한 설정 (도커 컨테이너 내부에서 읽을 수 있도록 허용)
sudo chmod 644 /etc/secrets/firebase-key.json
```

---

## 🏗️ [3단계] 인스턴스 내 서비스별 도커 이미지 빌드

각 서비스의 최신 코드를 로컬 환경이 아닌 **인스턴스 내부에서 직접 도커 이미지로 빌드**합니다. 각 디렉토리 구조가 동일 레벨에 배치되어 있으므로 아래와 같이 손쉽게 빌드할 수 있습니다.

```bash
cd ~/

# 1. 프론트엔드 이미지 빌드 (Next.js)
cd ~/1-team-one-fe && docker build -t frontend:latest .

# 2. 백엔드 이미지 빌드 (Spring Boot)
cd ~/1-team-one-be && docker build -t backend:latest .

# 3. AI 서비스 이미지 빌드 (FastAPI)
cd ~/1-team-one-ai && docker build -t ai:latest .
```

* **추후 코드 변경 시 업데이트 방법:**
  원하는 서비스 레포지토리로 이동하여 `git pull`을 수행한 후, 동일한 빌드 명령어를 재실행하여 이미지를 갱신하면 됩니다.

---

## 🚀 [4단계] 서비스 배포 및 기동

인프라 설정 디렉토리에서 프로덕션 도커 컴포즈 파일을 사용해 서비스를 배포하고 구동합니다.

### 1. 작업 디렉토리 진입 및 환경 변수 파일 생성
```bash
cd ~/1-team-one-cloud/docker-infra
cp .env.prod .env
```

### 2. 프로덕션 환경 변수(`.env`) 세팅
`.env` 파일 내부의 필요한 데이터베이스 정보, API 키 등을 채워 넣습니다.
* **도커 이미지 태그 설정**:
  `docker-compose.prod.yml` 파일은 환경 변수로 이미지명을 커스텀할 수 있도록 유연하게 작성되어 있습니다. 인스턴스 로컬에서 빌드한 이미지를 바로 사용하려면 기본값인 `frontend:latest`, `backend:latest`, `ai:latest`를 그대로 타도록 비워두거나 아래와 같이 명시할 수 있습니다.
  ```ini
  FRONTEND_IMAGE_URI=frontend:latest
  BACKEND_IMAGE_URI=backend:latest
  AI_IMAGE_URI=ai:latest
  ```

### 3. [최초 1회 필수] SSL 인증서(Certbot) 발급
Nginx를 HTTPS(443) 보안 환경으로 서비스하기 위해 사전에 도메인 인증서를 1회 발급받아야 합니다. 아래 일회성 명령어를 수행하면 인증 완료 후 임시 인증 컨테이너가 자동으로 삭제됩니다.

```bash
docker run --rm \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d raisedeveloper.com -d www.raisedeveloper.com \
  --email [EMAIL_ADDRESS] --agree-tos --no-eff-email
```
> [!WARNING]
> 인증 과정에서 Let's Encrypt 검증 서버가 본 서버의 `http://[도메인]/.well-known/acme-challenge/` 경로에 접속하므로, **사전에 도메인 DNS(A 레코드)가 해당 EC2의 탄력적 고정 IP(EIP)로 연결**되어 있어야 하며, **80 포트가 외부 방화벽(보안 그룹 등)에서 열려 있어야** 합니다.

### 4. 서비스 기동
로컬에서 빌드된 이미지들과 인프라 컨테이너(MySQL, Redis, Kafka, Qdrant, Nginx)들을 백그라운드로 실행합니다.
```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## 🔍 모니터링 및 상태 확인 명령어

* **컨테이너 전체 상태 조회**:
  ```bash
  docker compose -f docker-compose.prod.yml ps
  ```

* **컨테이너 실시간 로그 확인**:
  ```bash
  docker compose -f docker-compose.prod.yml logs -f --tail=100
  ```

* **특정 서비스(예: backend) 로그 확인**:
  ```bash
  docker compose -f docker-compose.prod.yml logs -f backend
  ```

* **서비스 업데이트 후 재배포 시 (무중단 혹은 재시작)**:
  ```bash
  # 특정 서비스 재빌드 후 리스타트 (예: frontend)
  cd ~/1-team-one-fe && git pull && docker build -t frontend:latest .
  cd ~/1-team-one-cloud/docker-infra
  docker compose -f docker-compose.prod.yml up -d --no-deps frontend
  ```
