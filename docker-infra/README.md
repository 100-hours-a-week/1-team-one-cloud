# raisedeveloper 프로덕션 서비스 배포 및 구동 가이드 (Docker Compose)

이 디렉토리는 단일 EC2 인스턴스 환경에서 리소스를 극한으로 최적화하여 10여 개의 애플리케이션 및 미들웨어 컨테이너를 구동하기 위한 Docker Compose 설정 파일이 포함되어 있습니다.

---

## 🚀 배포 순서 및 명령어

EC2 인스턴스 터미널에 접속(`aws ssm start-session`)한 환경에서 아래 순서대로 수행합니다.

### 1단계. 소스 코드 가져오기 및 디렉토리 진입
```bash
git clone <레포지토리_주소>
cd 1-team-one-cloud/docker-infra
```

### 2단계. 프로덕션 환경 변수(.env) 설정
배포할 환경 설정 파일(`.prod.env`)의 내용을 기반으로 실제 도커가 바라볼 `.env` 파일을 생성합니다.
```bash
cp .prod.env .env
```
* **수동 체크 요약**: `.env` 내부의 데이터베이스 패스워드, JWT 시크릿, API Key 등이 온전한지 확인합니다.

---

### 3단계. [최초 1회 필수] SSL 인증서(Certbot) 발급
Nginx를 HTTPS(443) 보안 환경으로 띄우기 위해, 사전에 도메인 인증서를 1회 발급받아야 합니다. 아래 일회성 명령어를 수행하면 인증 완료 후 컨테이너가 깔끔하게 자동 자동 삭제(`--rm`)됩니다.

```bash
docker run --rm \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d raisedeveloper.com -d www.raisedeveloper.com \
  --email [EMAIL_ADDRESS] --agree-tos --no-eff-email
```
* **주의**: 인증 과정에서 Let's Encrypt 서버가 본 서버의 `http://[도메인]/.well-known/acme-challenge/` 경로에 접근하므로, 사전에 도메인 DNS(A 레코드)가 해당 EC2의 탄력적 고정 IP(EIP)로 올바르게 연결되어 있어야 합니다.

---

### 4단계. 프로덕션 서비스 전체 기동
무결성 검증을 마친 프로덕션용 컴포즈 설정을 기반으로 모든 컨테이너 서비스를 백그라운드로 구동합니다.
```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## 🔍 모니터링 및 상태 확인 명령어

* **컨테이너 전체 상태 조회**:
  ```bash
  docker compose -f docker-compose.prod.yml ps
  ```
  *(모든 서비스 상태가 `running` 또는 `healthy` 상태인지 점검합니다.)*

* **컨테이너 실시간 로그 확인**:
  ```bash
  docker compose -f docker-compose.prod.yml logs -f --tail=100
  ```

* **특정 서비스(예: backend) 로그 확인**:
  ```bash
  docker compose -f docker-compose.prod.yml logs -f backend
  ```
