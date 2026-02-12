# modules/security_groups/main.tf (Description만 수정)

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-alb-sg"
    }
  )
}

# Frontend Security Group
resource "aws_security_group" "frontend" {
  name        = "${var.environment}-frontend-sg"
  description = "Security group for Frontend instances"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-frontend-sg"
      Tier = "Web"
    }
  )
}

# Backend Security Group
resource "aws_security_group" "backend" {
  name        = "${var.environment}-backend-sg"
  description = "Security group for Backend instances"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB and Frontend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [
      aws_security_group.alb.id,
      aws_security_group.frontend.id
    ]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-backend-sg"
      Tier = "App"
    }
  )
}

# AI Security Group
resource "aws_security_group" "ai" {
  name        = "${var.environment}-ai-sg"
  description = "Security group for AI instances"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from Backend"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ai-sg"
      Tier = "App"
    }
  )
}

# MySQL Instance Security Group (Staging 전용)
resource "aws_security_group" "mysql_instance" {
  count = var.use_rds ? 0 : 1

  name        = "${var.environment}-mysql-instance-sg"
  description = "Security group for MySQL instance"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL from Backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-mysql-instance-sg"
      Tier = "Data"
    }
  )
}

# Redis Instance Security Group (공통)
resource "aws_security_group" "redis_instance" {
  name        = "${var.environment}-redis-instance-sg"
  description = "Security group for Redis instance"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis from Backend"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-redis-instance-sg"
      Tier = "Data"
    }
  )
}

# RDS Security Group (Production 전용)
resource "aws_security_group" "rds" {
  count = var.use_rds ? 1 : 0

  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS MySQL"  # 수정
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL from Backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-rds-sg"
      Tier = "Data"
    }
  )
}