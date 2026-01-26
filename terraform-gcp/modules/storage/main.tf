# 1. 이미지 저장용 GCS 버킷 생성
resource "google_storage_bucket" "image_bucket" {
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class

  # 실수로 버킷이 삭제되는 것을 방지
  force_destroy = false 

  # 균일한 버킷 수준 액세스 (ACL 사용 안 함)
  uniform_bucket_level_access = true

  # 공개 액세스 방지 (모든 접근은 Signed URL로만)
  public_access_prevention = "enforced"

  # CORS 설정 (프론트엔드 직접 업로드를 위해 필수)
  cors {
    origin          = var.cors_origins
    method          = ["GET", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "Access-Control-Allow-Origin", "x-goog-resumable"]
    max_age_seconds = 3600
  }
}

# 2. 백엔드 서버가 사용할 서비스 계정 (Service Account) 생성
# (이미 있다면 data source로 가져와서 사용 가능)
resource "google_service_account" "backend_sa" {
  account_id   = "backend-sa"
  display_name = "Backend API Service Account"
  project      = var.project_id
}

# 3. 서비스 계정에 '버킷 관리' 권한 부여 (업로드/다운로드용)
resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.image_bucket.name
  role   = "roles/storage.objectAdmin" # 읽기/쓰기/삭제 권한
  member = "serviceAccount:${google_service_account.backend_sa.email}"
}

# 4. 서비스 계정에 '토큰 생성' 권한 부여 (Signed URL 서명용)
# 키 파일(JSON) 없이 IAM 인증을 하려면 이 권한이 필수
resource "google_project_iam_member" "token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}