# ---------------------------------------------------------------------------
# Module Security Group
# Démontre le bloc "dynamic" : génère un bloc "ingress" par élément de la
# variable ingress_rules, sans dupliquer le code.
# ---------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.environment}-${var.name}-sg"
  description = "Security group ${var.name} - géré par Terraform"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # Egress ouvert par défaut (pratique courante, à restreindre si besoin de durcissement)
  egress {
    description = "Tout le trafic sortant autorisé"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # lifecycle : recrée le nouveau SG avant de détruire l'ancien,
  # évite une coupure si ce SG est attaché à des ressources actives
  lifecycle {
    create_before_destroy = true
  }
}
