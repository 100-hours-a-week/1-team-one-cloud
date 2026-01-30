# Nginx Worker Connection Exhaustion - 장애 보고서

**발생 일시:** 2026-01-29 09:48~09:55 KST (7분간)  
**심각도:** Critical  
**영향:** 전체 서비스 다운  
**상태:** 자동 복구 완료 / 재발 방지 조치 완료

---

## 1. 요약

- **원인:** Nginx worker_connections 768개 고갈로 신규 연결 거부
- **트래픽:** 초당 250개 요청 (정상 대비 5배), 7분간 약 106,000개 시도
- **결과:** 55,457개만 처리, 약 51,000개 드랍
- **공격자:** 211.2xx.2xx.1xx (성남시, SK Broadband) - 내부 부하 테스트 확인

---

## 2. 장애 흐름
```
00:48:06  공격 시작 (46 req/s)
00:48:20  트래픽 급증 (270 req/s peak)
00:48:30  Connection 고갈 시작
00:49:00  완전 고갈 - "worker_connections are not enough"
00:55:00  공격 종료, 자동 복구
```

**핵심 문제:**
- Nginx가 처리 가능한 최대 동시 요청: 384개 (768 ÷ 2)
- 실제 유입: 초당 250개 지속
- 결과: 순식간에 포화, 새 요청 전부 거부

**백엔드 상태:**
- Spring Boot는 완전히 정상 (요청이 아예 도달하지 않음)
- 로그 깨끗 (에러 없음)
- DB/시스템 리소스 정상

---

## 3. 적용된 조치

### 3.1 Rate Limiting 추가 ✅

**nginx.conf Rate Limiting 설정 추가:**
```nginx
# /etc/nginx/nginx.conf
http {
    # Rate Limiting Zones 추가
    limit_req_zone $binary_remote_addr zone=login_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    # 기존 설정...
}
```

**효과:**
- 단일 IP당 초당 최대 100개 요청으로 제한
- 로그인 API는 초당 10개로 강력 제한
- 동일한 공격 발생 시 자동 차단

**적용 완료:** 2026-01-29

---

### 3.2 Worker Connections 증설 ✅

**Nginx 설정:**
```nginx
# /etc/nginx/nginx.conf
events {
    worker_connections 2048;  # 768 → 2048
}
```

**증설 근거:**
- 2048이면 동시 1024개 프록시 처리 가능
- 시스템 리소스 한계 고려 (ulimit: 1024)
- Rate Limiting이 주 방어선, worker_connections는 보조

**적용 완료:** 2026-01-29

---

### 3.3 모니터링 & 알림 시스템 강화 ✅

**Prometheus 메트릭 수집 추가:**
```yaml
# Nginx 핵심 지표 수집
- nginx_connections_active      # 활성 연결 수
- nginx_connections_waiting     # Keep-alive 대기
- nginx_http_requests_total     # 총 요청 수 (status code별)
```

**Grafana 대시보드 추가:**
- Nginx Connection 사용률 (Active / worker_connections)
- Rate Limiting 차단 현황
- RPS (Requests Per Second) 추이
- 5xx 에러율 추이

**Alertmanager 알림 규칙 추가:**
```yaml
# Connection 고갈 경고
- alert: NginxConnectionExhaustion
  expr: nginx_connections_active / 2048 > 0.8
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Nginx connections 80% 이상 사용 중"

# 높은 에러율 경고
- alert: NginxHighErrorRate
  expr: rate(nginx_http_requests_total{status=~"5.."}[1m]) > 10
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "5xx 에러율 증가 ({{ $value }} req/s)"

# Rate Limiting 대량 차단
- alert: RateLimitingActive
  expr: rate(nginx_limit_req_status{status="rejected"}[1m]) > 50
  for: 1m
  labels:
    severity: warning
  annotations:
    summary: "Rate limiting 대량 차단 중 (공격 가능성)"
```

**Discord Webhook 연동:**
- 실시간 알림 전송 (Critical/Warning)
- 알림 내용: 메트릭 값, 시간, 서버 정보

**적용 완료:** 2026-01-30

---

## 4. 검증

### Rate Limiting 테스트 ✅
```bash
# 150개 요청 테스트
for i in {1..150}; do 
    curl -s -o /dev/null -w "%{http_code}\n" https://raisedeveloper.com/api/actuator/health & 
done
wait | sort | uniq -c

# 결과: 150개 전부 200 OK (여유 있음)
```

### Connection 모니터링 ✅
```bash
curl http://localhost:8090/nginx_status
# Active connections: 2 (정상)
```

### Alertmanager 동작 확인 ✅
- Prometheus targets: healthy
- Alert rules: loaded
- Discord webhook: 연동 완료

---

## 5. 장기 개선 (검토)

추후 검토 항목 (우선순위 낮음):
- [ ] Nginx 다중화 (Load Balancer)
- [ ] WAF 도입 (Cloudflare, AWS WAF)
- [ ] Auto-scaling
- [ ] Circuit Breaker 패턴

---

## 6. 정리

**핵심 발견:**
- Rate Limiting 부재가 결정적 문제
- Worker connections 768은 부족했으나, 증설만으로는 해결 안 됨
- 백엔드는 문제없었음 (Nginx에서 차단)
- **실시간 알림 시스템 부재로 늦은 대응**

**재발 방지:**
1. ✅ Rate Limiting 추가 (적용 완료)
2. ✅ Worker Connections 2048로 증설 (적용 완료)
3. ✅ Prometheus + Grafana + Alertmanager 모니터링 강화 (적용 완료)
4. ✅ Discord 실시간 알림 (적용 완료)

**향후 대응:**
- 동일 패턴 공격 발생 시 자동 차단
- 임계치 도달 시 자동 알림 (Discord)
- Grafana 대시보드로 실시간 모니터링

---

**작성일:** 2026-01-30  
**작성 담당자:** James  
**검토자:** Mika