# ---------------------------------------------------------------------------
# Module VPC
# Crée : un VPC, un Internet Gateway, des subnets publics/privés, les route
# tables associées, et (en option) un NAT Gateway.
# ---------------------------------------------------------------------------

# locals : valeurs calculées une seule fois et réutilisées dans tout le module
# (évite la répétition, améliore la lisibilité)
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "vpc"
    }
  )
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

# for_each sur une map(string) : chaque clé (ex "public-a") devient une ressource
# distincte et stable -> supprimer un subnet du dict ne perturbe pas les autres
# (contrairement à count, voir README section 3)
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block               = each.value
  # index() récupère la position de la clé pour répartir sur les AZ disponibles
  availability_zone       = data.aws_availability_zones.available.names[index(keys(var.public_subnets), each.key) % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[index(keys(var.private_subnets), each.key) % length(data.aws_availability_zones.available.names)]

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

# Association route table <-> chaque subnet public créé par for_each
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --- Partie conditionnelle : NAT Gateway (coûteux, donc optionnel) ---
# count = condition ? 1 : 0 est le pattern standard pour rendre une ressource
# optionnelle selon une variable booléenne.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  # values() + [0] : on prend le premier subnet public de la map pour héberger le NAT
  subnet_id = values(aws_subnet.public)[0].id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    # dynamic block : ne génère le bloc "route" que si le NAT est actif
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
