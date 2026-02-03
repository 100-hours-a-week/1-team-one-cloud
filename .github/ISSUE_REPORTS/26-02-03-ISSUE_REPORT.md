## 1. 개요
현재 우리 서비스의 병목 구간 분석을 위해 부하테스트를 진행한다.

특히 서비스의 핵심인 **알림 발송 직후 급격한 트래픽 유입**  상황에서의 안정성을 검증한다.

---

## 2. 테스트 환경 및 데이터 준비
### 2.1 인프라 구성
- **Server:** Spring Boot (Backend), Next.js (Frontend)
- **DB:** MySQL
- **Tool:** k6 (Docker 실행), Python (데이터 생성)
- **Network Latency:** GCP Central-1 기준 RTT Avg 175ms

---

### 2.2 더미 데이터 생성 (Data Seeding)
테스트의 정합성을 위해 1,000명 이상의 유저와 연관 데이터(프로필, 알림 설정, 루틴 등)를 생성.
<details><summary>📂 <b> generate_data.py (더미 데이터 생성 스크립트)</b></summary>

```Python
import jwt
import datetime
import csv
import json
import base64

# ==========================================
# 설정 (Spring Boot application.yml 참고)
# ==========================================
SECRET_KEY = "JWT_SECRET_KEY"              # security.jwt.secret-base64 값
ISSUER = "JWT_ISSUER"                      # security.jwt.issuer 값 (서버 발급 토큰과 일치시킴)
ALGORITHM = "HS256"
USER_COUNT = 1000

# 토큰 만료 시간 (10일)
EXPIRATION = datetime.datetime.now() + datetime.timedelta(days=10)

# 더미 비밀번호 (BCrypt 등으로 암호화된 문자열 예시 - 실제 로그인 테스트가 필요 없다면 아무 문자열이나 가능)
# 예: 'Pass1234!1'를 BCrypt로 암호화한 값
DUMMY_PASSWORD = "$2a$10$uOan4acgPJZ28VNgdQ3O7OZRhvB88kuceDua7n.J3PqynQcrcA61S"
# 로그인 API 요청용 원본 비밀번호
RAW_PASSWORD = "Pass1234!1"
# 알림 시작 시간 (HH:MM:SS)
# 예: 현재 시간이 10:05라면 '10:06:00'으로 설정
ALARM_START_TIME = "21:00:00"

# ==========================================
# 데이터 생성 로직
# ==========================================
tokens = []
users_json = []

# 각 테이블별 VALUE 리스트
users_values = []
profiles_values = []
alarms_values = []
fcm_values = []
submissions_values = []
routines_values = []
steps_values = []
user_characters_values = []
quest_progress_values = []

# 현재 요일 구하기 (예: "MONDAY") - 스케줄러가 오늘 바로 동작하도록 설정
current_day = datetime.datetime.now().strftime("%A").upper()

# 1. 기초 데이터 (FK 참조용) - surveys, exercises
# SQL 파일 최상단에 위치할 구문들
static_sql = [
    "-- 1. 기초 데이터: 더미 서베이 생성 (FK 제약 해결용)",
    "INSERT INTO surveys (id, version, is_active, created_at) VALUES (1, 1, 1, NOW()) ON DUPLICATE KEY UPDATE id=id;",
    "",
    "-- 2. 기초 데이터: 더미 운동 생성 (FK 제약 해결용)",
    "INSERT INTO exercises (id, name, content, effect, type, pose, body_part, difficulty, tags, is_deprecated, created_at, updated_at) "
    "VALUES (1, '숨쉬기', '편안하게 숨을 쉽니다', '심신안정', 'COUNT', '{}', 'WHOLE', 1, '기초', 0, NOW(), NOW()) ON DUPLICATE KEY UPDATE id=id;",
    "",
    "-- 3. 기초 데이터: 더미 퀘스트 생성 (FK 제약 해결용)",
    "INSERT INTO quests (id, name, quest_image_path, type, reward_exp, target_count, finished_at, created_at, updated_at) VALUES (1, '매일 스트레칭', 'default.png', 'DAILY', 10, 1, '2099-12-31 00:00:00', NOW(), NOW()) ON DUPLICATE KEY UPDATE id=id;",
    "",
]

# Secret Key 디코딩 (Spring Boot의 secret-base64 동작과 일치시킴)
# 패딩(=)이 빠져있을 경우를 대비해 보정 후 디코딩
missing_padding = len(SECRET_KEY) % 4
if missing_padding != 0:
    SECRET_KEY += '=' * (4 - missing_padding)
decoded_key = base64.b64decode(SECRET_KEY)

# 2. 대량 데이터 생성 루프
for i in range(1, USER_COUNT + 1):
    user_id = i
    email = f"user{i}@test.com"
    role = "USER"
    is_onboarding_completed = 1  # 1: True (온보딩 완료 상태로 가정)
    
    # 1. JWT 토큰 생성 (백엔드 JwtTokenProvider 로직에 맞춤)
    payload = {
        "iss": ISSUER,
        "uid": user_id,
        "email": email,
        "role": role,
        "typ": "ACCESS",
        "exp": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=10), # UTC 기준 만료 시간
        "iat": datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(seconds=60)  # UTC 기준 발급 시간
    }
    
    token = jwt.encode(payload, decoded_key, algorithm=ALGORITHM)
    
    # k6용 CSV 데이터 저장
    tokens.append([token])

    # k6용 JSON 데이터 저장 (로그인 테스트용)
    users_json.append({
        "username": email,
        "password": RAW_PASSWORD
    })

    # 2. SQL Values 생성
    # A. Users
    users_values.append(f"({user_id}, '{email}', '{DUMMY_PASSWORD}', '{role}', {is_onboarding_completed}, NOW(), NOW(), NULL)")

    # B. User Profiles (Nickname 필수)
    profiles_values.append(f"({user_id}, {user_id}, 'default.png', 'user_{user_id}', NOW(), NOW())")

    # C. Alarm Settings (중요: active_start_at ~ end_at을 하루 종일로 설정, 요일은 오늘로 설정)
    alarms_values.append(
        f"({user_id}, {user_id}, 60, '{ALARM_START_TIME}', '23:59:59', NULL, NULL, '{current_day}', 0, NOW(), NOW())"
    )

    # D. FCM Tokens (스케줄러 발송 로직 진입용)
    fcm_values.append(f"({user_id}, {user_id}, 'dummy_fcm_token_{user_id}', NOW(), NOW())")

    # E. Routine Data (createSession 성공을 위해 필수)
    # 1) Survey Submissions
    submissions_values.append(f"({user_id}, 1, {user_id}, NOW())") # survey_id=1

    # 2) Routines
    routines_values.append(f"({user_id}, {user_id}, {user_id}, 1, '부하테스트용', 1, 'PENDING', NOW())") # survey_submission_id=user_id (1:1 매핑 가정)

    # 3) Routine Steps
    steps_values.append(f"({user_id}, {user_id}, 1, 60, 1, NOW())") # routine_id=user_id, exercise_id=1

    # F. User Characters (DDL에 맞춰 컬럼 수정: type, name, level, exp, streak, status_score)
    user_characters_values.append(f"({user_id}, {user_id}, 'CHARLIE', 'Char{user_id}', 1, 0, 0, 0, NOW(), NOW())")

    # G. Quest Progress (DDL에 맞춰 컬럼 수정: status 제거, completed_at 추가)
    # id, user_id, quest_id, current_count, completed_at, created_at, updated_at
    quest_progress_values.append(f"({user_id}, {user_id}, 1, 0, NULL, NOW(), NOW())")
     
    
# ==========================================
# SQL 조합 (Bulk Insert)
# ==========================================
final_sql_statements = []
final_sql_statements.extend(static_sql)

def add_bulk_insert(table_name, columns, values_list):
    if not values_list:
        return
    header = f"INSERT INTO {table_name} ({columns}) VALUES"
    final_sql_statements.append(header)
    # 1000개씩 끊어서 넣거나 한 번에 넣기 (여기선 한 번에 처리, 메모리 주의)
    final_sql_statements.append(",\n".join(values_list) + ";")
    final_sql_statements.append("") # 빈 줄

add_bulk_insert("users", 
                "id, email, password, role, is_onboarding_completed, created_at, updated_at, deleted_at", 
                users_values)

add_bulk_insert("user_profiles", 
                "id, user_id, image_path, nickname, created_at, updated_at", 
                profiles_values)

add_bulk_insert("user_alarm_settings", 
                "id, user_id, alarm_interval, active_start_at, active_end_at, focus_start_at, focus_end_at, repeat_days, dnd, created_at, updated_at", 
                alarms_values)

add_bulk_insert("fcm_tokens", 
                "id, user_id, token, created_at, updated_at", 
                fcm_values)

add_bulk_insert("survey_submissions", 
                "id, survey_id, user_id, created_at", 
                submissions_values)

add_bulk_insert("routines", 
                "id, user_id, survey_submission_id, routine_order, reason, is_active, status, created_at", 
                routines_values)
    
add_bulk_insert("routine_steps", 
                "id, routine_id, exercise_id, limit_time, step_order, created_at", 
                steps_values)

add_bulk_insert("user_characters", 
                "id, user_id, type, name, level, exp, streak, status_score, created_at, updated_at",
                user_characters_values)

add_bulk_insert("quest_progress",
                "id, user_id, quest_id, current_count, completed_at, created_at, updated_at",
                quest_progress_values)


# ==========================================
# 파일 저장
# ==========================================

# 1. SQL 파일 저장
with open("dummy_users.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(final_sql_statements))
print(f"✅ SQL 파일 생성 완료: dummy_users.sql ({USER_COUNT}명)")

# 2. CSV 파일 저장 (k6 entry_storm용)
with open("users_token.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["token"])  # 헤더
    writer.writerows(tokens)
print(f"✅ CSV 파일 생성 완료: users_token.csv ({USER_COUNT}개)")

# 3. JSON 파일 저장 (k6 로그인 테스트용)
with open("users.json", "w", encoding="utf-8") as f:
    json.dump(users_json, f, indent=2)
print(f"✅ JSON 파일 생성 완료: users.json ({USER_COUNT}명)")

# 4. Cleanup SQL 파일 생성
cleanup_sql = """-- ==========================================
-- 부하 테스트 데이터 정리 스크립트
-- 주의: 이 스크립트는 모든 데이터를 삭제하므로 운영 DB에서는 절대 실행하지 마세요.
-- ==========================================

SET FOREIGN_KEY_CHECKS = 0; -- 외래 키 체크 비활성화 (TRUNCATE를 위해 필수)

-- 1. 유저 활동 및 보상 관련
TRUNCATE TABLE quest_progress;
TRUNCATE TABLE user_notifications;
TRUNCATE TABLE push_subscriptions;
TRUNCATE TABLE fcm_tokens;
TRUNCATE TABLE refresh_tokens;

-- 2. 유저 설정 및 프로필
TRUNCATE TABLE user_alarm_settings;
TRUNCATE TABLE user_characters;
TRUNCATE TABLE user_profiles;

-- 3. 커뮤니티 (게시글)
TRUNCATE TABLE post_tags;
TRUNCATE TABLE post_likes;
TRUNCATE TABLE post_images;
TRUNCATE TABLE posts;

-- 4. 운동 기록 및 루틴
TRUNCATE TABLE exercise_results;
TRUNCATE TABLE exercise_sessions;
TRUNCATE TABLE routine_steps;
TRUNCATE TABLE routines;

-- 5. 설문 응답 및 유저 계정
TRUNCATE TABLE survey_responses;
TRUNCATE TABLE survey_submissions;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1; -- 외래 키 체크 다시 활성화"""

with open("cleanup_data.sql", "w", encoding="utf-8") as f:
    f.write(cleanup_sql)
print(f"✅ SQL 파일 생성 완료: cleanup_data.sql")
```

</details><details><summary>📂 <b> fetch_tokens.py (토큰 발급 스크립트)</b></summary>

토큰을 생성했을 때 맞지 않아서 직접 로그인 후 토큰을 저장

```Python
import requests
import json
import csv
import time

# ==========================================
# 설정
# ==========================================
BASE_URL = "http://example.com:8080" # 실제 서버 주소
LOGIN_PATH = "/api/auth/login"              # 로그인 API 경로
USERS_FILE = "users.json"                   # 계정 정보 파일 (generate_data.py로 생성됨)
OUTPUT_FILE = "users_token.csv"             # 결과 저장 파일

def fetch_tokens():
    # 1. 유저 정보 로드
    try:
        with open(USERS_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except FileNotFoundError:
        print(f"❌ {USERS_FILE} 파일을 찾을 수 없습니다. generate_data.py를 먼저 실행해주세요.")
        return

    print(f"📋 {len(users)}명의 유저 정보를 로드했습니다. 서버({BASE_URL})로부터 토큰 발급을 시작합니다...")

    tokens = []
    success_count = 0
    fail_count = 0

    # 2. 로그인 요청 및 토큰 수집
    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['token']) # CSV 헤더

        for i, user in enumerate(users):
            try:
                # 로그인 요청
                response = requests.post(
                    f"{BASE_URL}{LOGIN_PATH}",
                    json={
                        "email": user["username"],
                        "password": user["password"]
                    },
                    headers={"Content-Type": "application/json"},
                    timeout=5 # 타임아웃 5초
                )

                if response.status_code == 200:
                    # 응답 JSON에서 토큰 추출
                    resp_json = response.json()
                    # 서버 응답 구조: data -> tokens -> accessToken -> token
                    token = resp_json.get('data', {}).get('tokens', {}).get('accessToken', {}).get('token')
                    
                    if token:
                        writer.writerow([token])
                        tokens.append(token)
                        success_count += 1
                    else:
                        print(f"⚠️ [{user['username']}] 응답에 토큰 필드가 없습니다: {resp_json}")
                        fail_count += 1
                else:
                    print(f"❌ [{user['username']}] 로그인 실패 (Status: {response.status_code}): {response.text}")
                    fail_count += 1

            except Exception as e:
                print(f"❌ [{user['username']}] 요청 중 에러 발생: {e}")
                fail_count += 1
            
            # 진행 상황 출력 (100명 단위)
            if (i + 1) % 100 == 0:
                print(f"   ... {i + 1}명 처리 완료 (성공: {success_count}, 실패: {fail_count})")
            

    print(f"\n✅ 작업 완료!")
    print(f"   - 총 시도: {len(users)}")
    print(f"   - 성공: {success_count}")
    print(f"   - 실패: {fail_count}")
    print(f"   - 저장된 파일: {OUTPUT_FILE}")

if __name__ == "__main__":
    fetch_tokens()

```
</details>

---

## 3. 시나리오 A: 접속 부하 (Entry Storm)

### 3.1 테스트 개요
- **목표:** 알림 발송 직후 1,000명의 사용자가 동시에 접속했을 때 페이지 로딩 및 핵심 데이터 조회 성능 검증.
- **API 구성:**
  - **Frontend:** `GET /` (Static/SSR)
  - **Backend:** `GET /api/users/me` (User Info)
  - **패턴:** Spike (30초 만에 1,000 VU 도달)

---

### 3.2 테스트 스크립트 (k6)
<details><summary>📂 <b> entry_storm.js</b></summary>
  
```JavaScript
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { SharedArray } from 'k6/data';

// ==============================================================================
// 접속 부하 (Entry Storm)
// 목표: 알림 발송 직후 사용자가 몰리는 상황(Spike)에서 메인 페이지와 핵심 API의 응답성 검증
// ==============================================================================

// CSV 파일에서 토큰 목록 불러오기 (메모리 효율을 위해 SharedArray 사용)
const userTokens = new SharedArray('users', function () {
    // users.csv 파일이 같은 폴더에 있다고 가정
    const f = open('./users_token.csv');
    // 줄바꿈으로 나누고 헤더(첫 줄)가 있다면 제외하거나 처리
    return f.split('\n').slice(1).map(s => s.trim()).filter(t => t !== '');
});

export const options = {
    // 부하 패턴: Spike Test (급격한 유입)
    stages: [
        { duration: '10s', target: 50 },   // 1. Warm up: 워밍업
        { duration: '30s', target: 1000 }, // 2. Spike: 알림 발송 후 30초 만에 1,000명 유입
        { duration: '1m', target: 1000 },  // 3. Peak: 1분간 최대 트래픽 유지 (서버가 버티는지 확인)
        { duration: '30s', target: 0 },    // 4. Cool down: 종료
    ],

    // 성능 목표 (SLA)
    thresholds: {
        http_req_duration: ['p(95)<1000'], // 원격지 지연(RTT ~200ms) 고려하여 1s로 상향
        http_req_failed: ['rate<0.01'],   // 에러율은 1% 미만이어야 함
    },
};

// 테스트 대상 URL (환경에 맞게 수정 필요)
const BASE_URL_FE = __ENV.BASE_URL_FE || 'http://localhost:3000'; // Next.js
const BASE_URL_BE = __ENV.BASE_URL_BE || 'http://localhost:8080'; // Spring Boot


export default function () {
    // 가상 유저에게 할당할 토큰을 순차적으로 선택
    const token = userTokens[__VU - 1];

    // [방어 코드] 토큰이 비정상적이면 요청을 보내지 않고 에러 로그 출력
    if (!token || token.length < 20) {
        console.error(`❌ Invalid Token for VU ${__VU}: '${token}'`);
        return;
    }

    // 공통 헤더 설정
    const params = {
        headers: {
            // 'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
        },
        tags: { name: 'BackendAPI' }, // 메트릭 태그 분리
    };

    // 1. 메인 페이지 진입 (Next.js)
    // 사용자가 앱/웹을 켰을 때 가장 먼저 요청되는 정적/SSR 리소스
    group('Front-end: Main Page Load', function () {
        const res = http.get(`${BASE_URL_FE}/`, { tags: { name: 'FrontendStatic' } });

        check(res, {
            'FE status is 200': (r) => r.status === 200,
            'FE load time < 500ms': (r) => r.timings.duration < 500,
        });
    });

    // 2. 백엔드 데이터 조회 (Spring Boot API)
    // 페이지 로딩과 동시에(또는 직후) 호출되는 API들을 병렬(Batch)로 요청하여 실제 브라우저 동작 시뮬레이션
    group('Back-end: User Data Fetch', function () {
        const responses = http.batch([
            ['GET', `${BASE_URL_BE}/api/users/me`, null, params],          // 사용자 정보 조회
        ]);

        // [디버깅] 200 OK가 아닌 경우 상세 로그 출력
        if (responses[0].status !== 200) {
            // 로그 폭주 방지를 위해 초반에만 출력
            if (__ITER < 3) {
                console.error(`❌ [Fail] Status: ${responses[0].status}, URL: ${responses[0].url}`);
                // 3xx 리다이렉트인 경우 Location 헤더 출력
                if (responses[0].status >= 300 && responses[0].status < 400) {
                    console.error(`   -> Redirect Location: ${responses[0].headers['Location']}`);
                } else {
                    console.error(`   -> Body: ${responses[0].body}`);
                }
            }
        }

        // 응답 검증
        check(responses[0], {
            'BE User Info status is 200': (r) => r.status === 200,
            'BE User Info duration < 300ms': (r) => r.timings.duration < 300,
        });
    });

    // 3. Think Time (사용자 대기 시간)
    // 접속 폭주 상황이라도 사용자가 화면을 인지하는 최소한의 시간 부여 (0.5~1.5초 랜덤)
    sleep(Math.random() * 1 + 0.5);
}

```
</details>

---

### 3.3 테스트 결과 및 분석
```Plaintext
  █ THRESHOLDS 
    ✗ http_req_duration.............: p(95)=3.14s (목표 < 1.0s 실패)
    ✓ http_req_failed...............: 0.00%

  █ SERVER METRICS
    - CPU Usage: 50% (여유)
    - HikariCP: Active 10 (Max), Pending 188
    - JVM Threads: 220 (Timed Waiting)
```

- **Latency 목표 미달:** 95%의 요청이 3.14초 이상 소요됨. 사용자 경험에 치명적임.
- **BE 병목 확인:** FE 로딩보다 BE 데이터 조회(duration < 300ms) 실패율이 높음.
- **원인 도출 (DB Connection Pool):**
  - CPU는 50%로 여유로우나, 스레드들이 일을 하지 못하고 대기 중(TIMED_WAITING).
  - **HikariCP Pending:** 188은 DB 커넥션을 얻기 위해 줄 서 있는 요청의 수임.
- **결론:** 기본 설정된 Connection Pool Size(10)가 동시 접속(RPS 300+)을 처리하기에 턱없이 부족함.

---

## 4. 시나리오 B: 로그인 부하 (Login Load)

### 4.1 테스트 개요
- **목표:** 대규모 유저의 로그인 요청 처리 능력 검증 (BCrypt 연산 부하 포함).
- **패턴:** Constant Arrival Rate (Soak Test) 또는 Ramping (Load Test).

---

### 4.2 테스트 스크립트(k6)

<details><summary>📂 <b> login_load.js</b></summary>

```JavaScript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';

// 1. 테스트 데이터 로드 (실제 유저 1,000명의 정보를 담은 JSON이나 CSV 권장)
const users = new SharedArray('users', function () {
  return JSON.parse(open('./users.json')); // { "username": "...", "password": "..." } 형태
});

// export const options = {
//   scenarios: {
//     login_load_test: {
//       executor: 'ramping-arrival-rate',  // 부하를 서서히 높이면서 어느 지점에서 서버가 다운되는지 관찰, 이후 constant로 넘어가
//       startRate: 0,
//       timeUnit: '1s',
//       preAllocatedVUs: 200,              // 부하를 위해 미리 준비할 유저 수
//       maxVUs: 1000,                      // 최대 유저 수 (응답이 느려질 경우 대비)
//       stages: [
//         { target: 200, duration: '5m' }, // 5분 동안 0에서 200까지 서서히 부하 증가
//       ],
//     },
//   },
//   thresholds: {
//     http_req_duration: ['p(95)<1500'],   // 원격지 지연 + BCrypt 연산 고려하여 1.5s로 상향
//     http_req_failed: ['rate<0.05'],     // 실패율 5% 미만 유지
//   },
// };

export const options = {
  scenarios: {
    login_load_test: {
      executor: 'constant-arrival-rate', // QPS를 일정하게 유지
      rate: 18,                          // 목표: 초당 18회 요청 (서버가 죽은 24QPS의 80% 수준)
      timeUnit: '1s',
      duration: '30m',                   // 30분간 지속
      preAllocatedVUs: 100,              // 부하를 위해 미리 준비할 유저 수
      maxVUs: 1000,                      // 최대 유저 수 (응답이 느려질 경우 대비)
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<1500'],   // 원격지 지연 + BCrypt 연산 고려하여 1.5s로 상향
    http_req_failed: ['rate<0.05'],     // 실패율 5% 미만 유지
  },
};

export default function () {
  // 2. 가상 사용자별로 랜덤한 유저 데이터 선택
  const user = users[Math.floor(Math.random() * users.length)];

  // 환경 변수에서 백엔드 URL을 가져옴 (기본값: 로컬호스트)
  const BASE_URL = __ENV.BASE_URL_BE || 'http://localhost:8080';
  const url = `${BASE_URL}/api/auth/login`;
  const payload = JSON.stringify({
    email: user.username, // username -> email 변경
    password: user.password,
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
  };

  // 3. 로그인 요청 실행
  const res = http.post(url, payload, params);

  // 4. 검증
  const loginSuccess = check(res, {
    'is status 200': (r) => r.status === 200,
    'has token': (r) => r.body && r.json('data.tokens.accessToken.token') !== undefined,
  });

  // 5. 로그인 성공 시 루틴 정보 조회
  if (loginSuccess) {
    const token = res.json('data.tokens.accessToken.token');
    const authParams = {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    };

    const routineRes = http.get(`${BASE_URL}/api/users/me/routines`, authParams);
    check(routineRes, {
      'routines status is 200': (r) => r.status === 200,
    });
  }
}
```
</details>

---

### 4.2 테스트 결과 (실패)
- 동시 접속 200명 수준에서 Fail 발생.
- **원인:** Entry Storm과 동일하게 HikariCP 고갈로 인한 타임아웃.

---

### 4.3 개선 조치 사항
HikariCP 튜닝이 필요.
- **공식:** $Connections = ((Core Count \times 2) + Effective Spindle Count)$
- **적용:** e2-medium (2 vCPU) 기준 최소 5-10개이나, 트랜잭션 대기 시간을 고려하여 30-50개로 증설 후 재테스트 필요.

```YAML
# application.yml 수정 예시
spring:
  datasource:
    hikari:
      maximum-pool-size: 30      # 10 -> 30 증설
      minimum-idle: 30           # 고정 사이즈 유지
      connection-timeout: 30000
```

---

## 5. 시나리오 C: 데이터 볼륨 (스케줄러 성능)

### 5.1 테스트 개요
- **방식:** API 호출이 아닌, DB에 대량 데이터(1,000명) 적재 후 실제 스케줄러 실행 로그 분석.
- **목표:** 정해진 시간(Cron)에 병목 없이 알림 발송 로직이 1분(60,000ms) 내에 완료되는지 검증.

---

### 5.2 실행 로그 및 구간별 소요 시간 분석
```Bash
2026-01-31 21:00:00 PushAlarmScheduler   : 푸시 알람 스케줄러 시작

2026-01-31 21:00:00 PushAlarmScheduler   : active 시간/요일 대상 알람 설정 조회 완료: 1000 건

2026-01-31 21:00:05 PushAlarmScheduler   : 알람 전송 대상 알람 설정 필터 완료: 1000 건

2026-01-31 21:00:33 PushAlarmScheduler   : 세션 생성 완료: 1000 건

2026-01-31 21:01:19 PushAlarmScheduler   : 푸시 알람 스케줄러 완료: 세션 생성 건수=1000, 소요 시간=79975ms
```

| 단계 | 작업 내용 | 시작 시각 | 종료 시각 | 소요 시간 | 비고 |
| --- | --- | --- | --- | --- | --- |
| Step 1 | 대상 사용자 조회 (DB) | 00.002 | 00.662 | 0.66초 | 매우 빠름 (정상) |
| Step 2 | 필터링 (DB 조회 포함) | 00.662 | 05.289 | 4.63초 | 다소 느림 (N+1 문제 의심) |
| Step 3 | 세션 생성 (DB 쓰기) | 05.289 | 33.574 | 28.29초 | 느림 (병목 2) |
| Step 4 | 알림 발송 (Network I/O) | 33.574 | 79.975 | 46.40초 | 매우 느림 (주요 병목) |

1. **Network I/O Blocking (Step 4):**
  - **현재 구조:** Loop 돌면서 1명씩 발송 -> 응답 대기 -> 다음 발송.
  - **계산:** $46.4s / 1000 \approx 46ms/건$. (네트워크 RTT 대기 시간)
  - **개선:** CompletableFuture 또는 @Async를 적용하여 비동기 병렬 처리로 변경해야 함.
2. **DB I/O Blocking (Step 3):**
  - **현재 구조:** 1,000번의 개별 트랜잭션 및 커밋.
  - **개선:** JDBC Template 등을 활용한 Bulk Insert 도입 필요.
3. **N+1 Query (Step 2):**
  - **개선:** Join Fetch를 사용하거나 데이터를 메모리에 한 번에 로드하여 애플리케이션 레벨에서 필터링.

---

## 6. 종합 결론
이번 부하 테스트를 통해 **서버 리소스(CPU)는 충분하나, DB 연결과 I/O 처리 방식에서 심각한 병목**이 있음을 확인했습니다.
1. **안정성:** 500 에러 없이 로직은 정상 동작함 (성공).
2. **성능:** 목표 응답 시간(1s) 달성 실패 (3.14s)
3. **Next Step:**
   - HikariCP maximum-pool-size 30으로 증설.
   - 알림 발송 로직 비동기(Async) 리팩토링.
   - JPA N+1 문제 해결 및 Bulk Insert 적용.
  
위 개선 사항 적용 후 2차 부하 테스트를 진행하여 p95 < 1.0s 달성 여부를 검증할 예정

---

**작성일:** 2026-02-03  
**작성 담당자:** Mika  
**검토자:** James, Brian
