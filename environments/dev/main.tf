# ---------------------------------------------------------------------------
# Module racine de l'environnement DEV
# Assemble les modules vpc / security-group / ec2.
# C'est le SEUL endroit où l'on branche les modules ensemble via leurs
# outputs -> inputs (module.vpc.vpc_id passé au module security-group, etc.)
# ---------------------------------------------------------------------------

locals {
  common_tags = {
    Environment = var.environment
    Project     = "myapp"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = false # false en dev pour limiter les coûts
  tags               = local.common_tags
}

module "web_sg" {
  source = "../../modules/security-group"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  name        = "web"

  ingress_rules = [
    {
      description = "HTTP depuis internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH restreint (à remplacer par ton IP réelle)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["203.0.113.0/32"]
    }
  ]

  tags = local.common_tags
}

module "app_servers" {
  source = "../../modules/ec2"

  environment                = var.environment
  instance_count             = var.instance_count
  instance_type               = var.instance_type
  subnet_ids                  = module.vpc.public_subnet_ids
  security_group_ids          = [module.web_sg.security_group_id]
  enable_detailed_monitoring = false
  db_password                = var.db_password

  tags = local.common_tags
}
