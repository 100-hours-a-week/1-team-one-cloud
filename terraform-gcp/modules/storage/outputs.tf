output "bucket_name" {
  description = "The name of the created bucket"
  value       = google_storage_bucket.image_bucket.name
}

output "service_account_email" {
  description = "The email of the backend service account"
  value       = google_service_account.backend_sa.email
}