module "network" {
  source = "../../modules/network"

  # variables.tf에 정의한 변수 주입
  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  subnet_cidr       = "10.0.1.0/24"
  ssh_source_ranges = var.ssh_source_ranges
}

module "compute" {
  source = "../../modules/compute"

  project_id            = var.project_id
  zone                  = var.zone
  instance_name         = var.instance_name
  machine_type          = var.machine_type
  boot_disk_size        = var.boot_disk_size
  service_account_email = var.service_account_email
  boot_disk_image       = var.boot_disk_image
  boot_disk_type        = var.boot_disk_type

  # Network 모듈에서 생성한 서브넷 정보 전달
  subnet_self_link = module.network.subnet_self_link
}

module "storage" {
  source = "../../modules/storage"

  project_id    = var.project_id
  location      = var.region
  bucket_name   = "${var.project_id}-images-dev" # 이름 충돌 방지를 위해 프로젝트ID 포함
  cors_origins  = var.cors_origins
  storage_class = var.storage_class
}