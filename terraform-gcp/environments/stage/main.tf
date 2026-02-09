# 고정 IP 예약
resource "google_compute_address" "static" {
  name    = "${var.instance_name}-ip"
  region  = var.region
  project = var.project_id
}

module "network" {
  source = "../../modules/network"

  # variables.tf에 정의한 변수 주입
  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  subnet_cidr       = "10.0.3.0/24" # Dev(10.0.1.0), Prod(10.0.2.0)와 겹치지 않게 설정
  ssh_source_ranges = var.ssh_source_ranges
  
  # Prod VPC 사용 설정
  use_existing_vpc = true
  vpc_name         = "prod-vpc"
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

module "storage" {
  source = "../../modules/storage"

  project_id           = var.project_id
  location             = var.region
  bucket_name          = "raise-developer-staging-bucket" # Prod와 이름 충돌 방지
  service_account_name = "backend-staging-sa"             # Prod와 ID 충돌 방지
  cors_origins         = var.cors_origins
  storage_class        = var.storage_class
}

# 운영 환경 모니터링 서버에서 스테이징 인스턴스 접근 허용 (방화벽 규칙)
resource "google_compute_firewall" "allow_prod_monitoring" {
  # prod_monitoring_source_ranges 변수에 값이 있을 경우에만 생성
  count   = length(var.prod_monitoring_source_ranges) > 0 ? 1 : 0
  name    = "${var.environment}-allow-prod-monitoring"
  network = module.network.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["9100", "9113", "9104", "8000", "8080", "9090"]
  }

  source_ranges = var.prod_monitoring_source_ranges

  # 메트릭 수집이 필요한 인스턴스에만 규칙을 적용하려면 target_tags를 지정하세요.
  # 예: target_tags = ["backend-server"]
  # 지정하지 않으면 서브넷 내 모든 인스턴스에 적용됩니다.
}