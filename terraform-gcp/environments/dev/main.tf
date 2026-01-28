# 1. Network 모듈 대신 Data Source 사용 (기존 Default VPC 사용)
data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

# 2. 방화벽 규칙 직접 정의 (Default VPC용)
resource "google_compute_firewall" "allow_ssh" {
  name    = "default-allow-ssh"
  network = data.google_compute_network.default.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-enabled"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "allow-web-public"
  network = data.google_compute_network.default.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_ai_server" {
  name    = "allow-ai-server"
  network = data.google_compute_network.default.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ai-server"]
}

module "compute" {
  source = "../../modules/compute"

  project_id            = var.project_id
  zone                  = var.zone
  instance_name         = var.instance_name
  machine_type          = var.machine_type
  boot_disk_size        = var.boot_disk_size
  service_account_email = module.storage.service_account_email
  boot_disk_image       = var.boot_disk_image
  boot_disk_type        = var.boot_disk_type
  tags                  = ["ssh-enabled", "web-server", "ai-server"]

  # Data Source로 가져온 Default 서브넷 정보 전달
  subnet_self_link = data.google_compute_subnetwork.default.self_link
}

module "storage" {
  source = "../../modules/storage"

  project_id    = var.project_id
  location      = var.region
  bucket_name   = "raise-developer-bucket"
  service_account_name = "backend-sa"
  cors_origins  = var.cors_origins
  storage_class = var.storage_class
}