# outputs.tf
# Terraform 실행 결과로 출력되는 값들을 정의
# 즉, 직접적인 실행 코드가 아닌 apply 후 바로 확인하기 위함

output "instance_name" {
  description = "VM 인스턴스 이름"
  value       = google_compute_instance.main.name
}

output "instance_external_ip" {
  # 실제 IP는 terraform apply 후에 GCP가 할당
  # 여기는 어디서 가져올지 경로만 정의
  description = "VM 외부 IP"
  value       = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  # VPC 내부에서 사용하는 사설 IP (10.128.x.x)
  description = "VM 내부 IP"
  value       = google_compute_instance.main.network_interface[0].network_ip
}