# modules/s3/main.tf

# 이미지 버킷 
resource "aws_s3_bucket" "image" {
  bucket        = var.image_bucket_name
  force_destroy = false

  tags = merge(var.tags, {
    Name    = var.image_bucket_name
    Service = "image-storage"
  })
}

resource "aws_s3_bucket_versioning" "image" {
  bucket = aws_s3_bucket.image.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "image" {
  bucket = aws_s3_bucket.image.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "image" {
  bucket = aws_s3_bucket.image.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false  # Bucket Policy 허용
  restrict_public_buckets = false  # Public 접근 허용
}

resource "aws_s3_bucket_policy" "image_public_read" {
  bucket     = aws_s3_bucket.image.id
  depends_on = [aws_s3_bucket_public_access_block.image]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.image.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "image" {
  bucket = aws_s3_bucket.image.id

  cors_rule {
    allowed_origins = var.cors_origins
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_headers = ["Content-Type", "Access-Control-Allow-Origin", "x-amz-*"]
    max_age_seconds = 3600
  }
}

# 배포 버킷
resource "aws_s3_bucket" "deploy" {
  bucket        = var.deploy_bucket_name
  force_destroy = false

  tags = merge(var.tags, {
    Name    = var.deploy_bucket_name
    Service = "deployment"
  })
}

resource "aws_s3_bucket_versioning" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# 배포 버킷 Bucket Policy → IAM Role 생성 후 콘솔에서 적용