# 고정 IP 예약
resource "google_compute_address" "static" {
  name   = "${var.instance_name}-ip"
  region = var.region
  project = var.project_id
}

# 고정 IP 예약 (모니터링 인스턴스)
resource "google_compute_address" "monitoring_static" {
  name    = "${var.monitoring_instance_name}-ip"
  region  = var.region
  project = var.project_id
}

module "network" {
  source = "../../modules/network"

  # variables.tf에 정의한 변수 주입
  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  subnet_cidr       = "10.0.2.0/24"
  ssh_source_ranges = var.ssh_source_ranges
  admin_ip = var.admin_ip
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
  static_ip             = google_compute_address.static.address

  # Network 모듈에서 생성한 서브넷 정보 전달
  subnet_self_link = module.network.subnet_self_link
}

# 모니터링 전용 서비스 계정 (권한 없음)
resource "google_service_account" "monitoring_sa" {
  account_id   = "monitoring-sa"
  display_name = "Monitoring Server Service Account"
  project      = var.project_id
}

# 모니터링 인스턴스 (모듈 사용하지 않고 직접 정의 - 재사용성 없음)
resource "google_compute_instance" "monitoring" {
  name         = var.monitoring_instance_name
  machine_type = var.monitoring_machine_type
  zone         = var.zone
  project      = var.project_id
  allow_stopping_for_update = true
  
  tags = ["ssh-enabled"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.monitoring_boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = module.network.subnet_self_link
    access_config {
      nat_ip = google_compute_address.monitoring_static.address
    }
  }

  service_account {
    email = google_service_account.monitoring_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}

module "storage" {
  source = "../../modules/storage"

  project_id    = var.project_id
  location      = var.region
  bucket_name   = "raise-developer-prod-bucket"
  service_account_name = "backend-prod-sa"
  cors_origins  = var.cors_origins
  storage_class = var.storage_class
}