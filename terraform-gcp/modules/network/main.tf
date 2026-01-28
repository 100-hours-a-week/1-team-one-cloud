# 1. VPC 생성
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false # 자동 생성 끔
  project                 = var.project_id
}

# 2. Subnet 생성
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet-01"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# 3. 방화벽 규칙: SSH 허용
resource "google_compute_firewall" "allow_ssh_public" {
  description  = "Allow SSH from anywhere"
  name         = "${var.environment}-allow-ssh"
  network      = google_compute_network.vpc.name
  project      = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  
  # 이 태그가 달린 인스턴스에만 규칙 적용
  target_tags   = ["ssh-enabled"]
}

# 4. 방화벽 규칙: 웹 트래픽 허용 (HTTP/HTTPS)
resource "google_compute_firewall" "allow_web" {
  name    = "${var.environment}-allow-web"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# 5. 방화벽 규칙: 내부 통신 허용 (나중에 DB 분리 등을 위해 필수)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  # 소스가 우리 서브넷 대역일 때만 허용
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

# 6. 방화벽 규칙: 모니터링 대시보드 (Grafana, Prometheus)
resource "google_compute_firewall" "allow_monitoring" {
  name    = "${var.environment}-allow-monitoring"
  network = google_compute_network.vpc.name
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["3000", "9090", "9093"]  # Grafana: 3000, Prometheus: 9090, AlertManager: 9093
  }
  
  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["monitoring-server"]
}
