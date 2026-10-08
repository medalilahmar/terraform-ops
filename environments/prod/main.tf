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
  enable_nat_gateway = true # true en prod : les subnets privés ont besoin d'un accès sortant
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
      description = "SSH interdit depuis internet en prod : accès via bastion uniquement"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # uniquement depuis l'intérieur du VPC
    }
  ]

  tags = local.common_tags
}

module "app_servers" {
  source = "../../modules/ec2"

  environment                = var.environment
  instance_count             = var.instance_count
  instance_type               = var.instance_type
  subnet_ids                  = module.vpc.private_subnet_ids # en prod, les serveurs app sont en subnet privé (derrière un LB, non détaillé ici)
  security_group_ids          = [module.web_sg.security_group_id]
  enable_detailed_monitoring = true # monitoring détaillé activé en prod
  db_password                = var.db_password

  tags = local.common_tags
}
