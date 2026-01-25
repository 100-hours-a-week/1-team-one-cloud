# main.tf
# 실제 생성/관리할 GCP 리소스를 정의하는 핵심 파일
# 역할:
#   1. VPC, VM, 방화벽 등 인프라 리소스 선언
#   2. 리소스 간 의존성 관리 (network → firewall → instance)
#   3. terraform apply 실행 시 이 파일 기준으로 인프라 생성/수정

# 네트워크: VPC
resource "google_compute_network" "default" {
  name                    = "default"
  description             = "Default network for the project"
  auto_create_subnetworks = true          # 각 리전에 자동으로 서브넷 생성
  routing_mode            = "REGIONAL"    # 리전 단위 라우팅
}

# Compute: VM 인스턴스
resource "google_compute_instance" "main" {
  # variables.tf에서 선언한 변수들 사용
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # 네트워크 태그: 방화벽 규칙 적용 대상 지정
  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20260117"
      size  = var.boot_disk_size
      type  = "pd-balanced"         # SSD와 HDD 중간 성능
    } 
  }

  network_interface {
    # 위에서 정의한 VPC 참조
    network = google_compute_network.default.self_link
    access_config {
      # 빈 블록 = "외부 IP 자동 할당"
      # GCP가 임시(ephemeral) 공인 IP 부여
    }
  }

  # VM이 사용할 서비스 계정 (GCP API 접근 권한)
  service_account {
    email  = "1053620326562-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",          # Cloud Storage 읽기
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  # Shielded VM 보안 설정
  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Lifecycle 설정: 중요 속성 변경 시 재생성 방지
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],  # SSH 키는 GCP 콘솔에서 자동 관리되므로 Terraform이 변경 감지 무시
    ]
  }
}

# 방화벽: SSH 접속 허용
resource "google_compute_firewall" "allow_ssh" {
  name        = "default-allow-ssh"
  network     = google_compute_network.default.name
  description = "Allow SSH from anywhere"
  priority    = 65534  # 낮을수록 우선순위 높음 (1~65534)

  allow {
    protocol = "tcp"
    ports    = ["22"]  # SSH 포트
  }

  source_ranges = ["0.0.0.0/0"] # 모든 IP 허용 (개발중에만...)
}

# 방화벽: HTTP 접속 허용
resource "google_compute_firewall" "allow_http" {
  name    = "default-allow-http"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"] # 이 태그 가진 인스턴스만 적용
}

# 방화벽: HTTPS 접속 허용
resource "google_compute_firewall" "allow_https" {
  name    = "default-allow-https"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"] # 이 태그 가진 인스턴스만 적용
}

# 방화벽: 웹 트래픽 허용 (HTTP + HTTPS)
resource "google_compute_firewall" "allow_web_public" {
  name    = "allow-web-public"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}
