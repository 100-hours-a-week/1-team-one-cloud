# AWS 프로바이더 설정
provider "aws" {
  region = var.aws_region
}

# 1. 네트워크 인프라 구성
# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # SSM 사용을 위해 DNS 호스트네임 활성화 권장
  enable_dns_support   = true

  tags = {
    Name = "${var.instance_name}-vpc"
  }
}

# 인터넷 게이트웨이 생성 및 VPC 연결
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.instance_name}-igw"
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # 퍼블릭 IP 자동 할당

  tags = {
    Name = "${var.instance_name}-public-subnet"
  }
}

# 라우팅 테이블 생성 (외부 트래픽을 IGW로 전달)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.instance_name}-public-rt"
  }
}

# 라우팅 테이블과 서브넷 연결
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 2. IAM 및 권한 설정 (SSM Session Manager 용)
# EC2 서비스용 IAM 역할 생성
resource "aws_iam_role" "ssm_role" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# SSM 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# 3. 보안 그룹 설정
resource "aws_security_group" "web_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  # 인바운드: 80 (HTTP) 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 인바운드: 443 (HTTPS) 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: 모든 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# 4. 컴퓨팅 및 할당
# 최신 Ubuntu 22.04 LTS AMI 조회
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 공식 계정

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "app" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_size           = 16
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # 자동 프로비저닝 (Docker 및 Docker Compose 설치)
  user_data = <<-EOF
              #!/bin/bash
              # 4GB 스왑 파일 생성 및 활성화 (OOM 방지)
              fallocate -l 4G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab

              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              
              # Docker 공식 GPG 키 추가 및 저장소 설정
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              # Docker 엔진 설치
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              
              # 서비스 활성화
              systemctl start docker
              systemctl enable docker
              
              # docker-compose 별칭 설정
              ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
              EOF

  tags = {
    Name = var.instance_name
  }
}

# 탄력적 IP 생성
resource "aws_eip" "eip" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name = "${var.instance_name}-eip"
  }
}

# 5. S3 버킷 설정 (기존 버킷 raise-developer-production-bucket 재사용으로 인해 신규 프로비저닝은 주석 처리)
# resource "aws_s3_bucket" "app_bucket" {
#   bucket        = "raise-developer-bucket"
#   force_destroy = false # 프로덕션 중요 데이터 유실 방지
# }
# 
# # 웹 프론트엔드에서 Pre-signed URL을 통해 직접 PUT 업로드할 수 있도록 CORS 허용
# resource "aws_s3_bucket_cors_configuration" "app_bucket_cors" {
#   bucket = aws_s3_bucket.app_bucket.id
# 
#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "PUT", "POST", "HEAD"]
#     allowed_origins = ["https://raisedeveloper.com", "https://www.raisedeveloper.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# }
# 
# # 퍼블릭 액세스 차단 규칙 완화 (GetObject 정책 적용 목적)
# resource "aws_s3_bucket_public_access_block" "app_bucket_public" {
#   bucket = aws_s3_bucket.app_bucket.id
# 
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }
# 
# # 버킷 정책: 오직 단일 파일 읽기(s3:GetObject)만 전 세계에 허용 (s3:ListBucket 등은 철저히 격리 차단)
# resource "aws_s3_bucket_policy" "public_read_policy" {
#   bucket = aws_s3_bucket.app_bucket.id
#   depends_on = [aws_s3_bucket_public_access_block.app_bucket_public]
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObjectOnly"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "${aws_s3_bucket.app_bucket.arn}/*"
#       }
#     ]
#   })
# }

# EC2 인스턴스의 IAM 역할에 S3 권한 추가 부여 (기존 버킷 연동 및 Access Key 노출 방지를 위해 필수적으로 유지)
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# EC2 인스턴스의 IAM 역할에 ECR Read 권한 추가 부여 (프라이빗 ECR 이미지 Pull 기능 목적)
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

