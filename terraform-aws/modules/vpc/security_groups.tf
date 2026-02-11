# modules/vpc/security_groups.tf

# ALB
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
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

# Frontend
resource "aws_security_group" "frontend" {
  name        = "${var.environment}-frontend-sg"
  description = "Security group for Frontend instances"
  vpc_id      = aws_vpc.main.id

  # From ALB
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

# Backend
resource "aws_security_group" "backend" {
  name        = "${var.environment}-backend-sg"
  description = "Security group for Backend instances"
  vpc_id      = aws_vpc.main.id

  # From ALB + Frontend(SSR)
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

# AI
resource "aws_security_group" "ai" {
  name        = "${var.environment}-ai-sg"
  description = "Security group for AI instances"
  vpc_id      = aws_vpc.main.id

  # From Backend
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

# RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  # From Backend
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