# 1. VPC 생성 (조건부)
resource "google_compute_network" "vpc" {
  count                   = var.use_existing_vpc ? 0 : 1
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false # 자동 생성 끔
  project                 = var.project_id
}

# 1-1. 기존 VPC 참조 (조건부)
data "google_compute_network" "vpc" {
  count   = var.use_existing_vpc ? 1 : 0
  name    = var.vpc_name
  project = var.project_id
}

# 2. Subnet 생성
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet-01"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = var.use_existing_vpc ? data.google_compute_network.vpc[0].id : google_compute_network.vpc[0].id
  project       = var.project_id
}

# 3. 방화벽 규칙: SSH 허용
resource "google_compute_firewall" "allow_ssh_public" {
  description  = "Allow SSH from anywhere"
  name         = "${var.environment}-allow-ssh"
  network      = var.use_existing_vpc ? data.google_compute_network.vpc[0].name : google_compute_network.vpc[0].name
  project      = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-enabled"]
}

# 4. 방화벽 규칙: 웹 트래픽 허용 (HTTP/HTTPS)
resource "google_compute_firewall" "allow_web" {
  name    = "${var.environment}-allow-web"
  network = var.use_existing_vpc ? data.google_compute_network.vpc[0].name : google_compute_network.vpc[0].name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# 5. 방화벽 규칙: 내부 통신 허용
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = var.use_existing_vpc ? data.google_compute_network.vpc[0].name : google_compute_network.vpc[0].name
  project = var.project_id

  # 소스가 해당 서브넷 대역(var.subnet_cidr) 내부일 때만 통신 허용 (동일 서브넷 간 통신)
  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

# 6. 방화벽 규칙: 운영 서버 포트(3000, 8080) 허용 - 관리자 IP 한정
resource "google_compute_firewall" "allow_app_admin" {
  name    = "${var.environment}-allow-app-admin"
  network = var.use_existing_vpc ? data.google_compute_network.vpc[0].name : google_compute_network.vpc[0].name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080"]
  }

  # SSH 허용 IP 대역(관리자 IP)을 사용하여 접근 제한
  source_ranges = var.admin_ip
  target_tags   = ["web-server"]
}
