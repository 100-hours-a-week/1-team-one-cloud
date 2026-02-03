output "vpc_name" {
  description = "The name of the VPC"
  value       = var.use_existing_vpc ? data.google_compute_network.vpc[0].name : google_compute_network.vpc[0].name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = var.use_existing_vpc ? data.google_compute_network.vpc[0].id : google_compute_network.vpc[0].id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "The self-link of the subnet"
  value       = google_compute_subnetwork.subnet.self_link
}
