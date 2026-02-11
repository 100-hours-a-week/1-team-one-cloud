# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  # dns 호스트명 활성화 (ALB, EC2 간 dns 기반 통신)
  enable_dns_hostnames = true
  # dns 확인 활성화: vpc 내부 dns 서버 활성화 (컨테이너 간 dns 통신)
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}