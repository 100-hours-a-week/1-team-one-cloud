output "monitoring_instance_ip" {
  description = "모니터링 인스턴스의 고정 외부 IP"
  value       = google_compute_address.monitoring_static.address
}

output "monitoring_instance_name" {
  description = "모니터링 인스턴스 이름"
  value       = google_compute_instance.monitoring.name
}

output "grafana_url" {
  description = "Grafana 대시보드 URL"
  value       = "http://${google_compute_address.monitoring_static.address}:3000"
}

output "prometheus_url" {
  description = "Prometheus 대시보드 URL"
  value       = "http://${google_compute_address.monitoring_static.address}:9090"
}