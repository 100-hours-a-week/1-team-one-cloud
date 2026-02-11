
# modules/vpc/subnets.tf
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true  # 퍼블릭 IP 자동 할당

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-public-${element(split("-", var.availability_zones[count.index]), 2)}"
      Tier = "Public"
    }
  )
}

resource "aws_subnet" "private_web" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_web_subnet_cidr
  availability_zone = var.availability_zones[0]  # ap-northeast-2a

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-web-2a"
      Tier = "Web"
    }
  )
}

resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidr
  availability_zone = var.availability_zones[0]  # ap-northeast-2a

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-app-2a"
      Tier = "App"
    }
  )
}

resource "aws_subnet" "private_data" {
  count = length(var.private_data_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-private-data-${element(split("-", var.availability_zones[count.index]), 2)}"
      Tier = "Data"
    }
  )
}