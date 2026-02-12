# modules/s3/outputs.tf

output "image_bucket_id" {
  description = "이미지 버킷 ID"
  value       = aws_s3_bucket.image.id
}

output "image_bucket_arn" {
  description = "이미지 버킷 ARN"
  value       = aws_s3_bucket.image.arn
}

output "image_bucket_domain" {
  description = "이미지 버킷 도메인 (공개 URL용)"
  value       = aws_s3_bucket.image.bucket_regional_domain_name
}

output "deploy_bucket_id" {
  description = "배포 버킷 ID"
  value       = aws_s3_bucket.deploy.id
}

output "deploy_bucket_arn" {
  description = "배포 버킷 ARN"
  value       = aws_s3_bucket.deploy.arn
}