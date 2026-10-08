# ---------------------------------------------------------------------------
# Contraintes de version : reproductibilité garantie entre les machines
# (dev, collègues, CI/CD). Bonne pratique OBLIGATOIRE en pro.
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # accepte 5.x, refuse 6.0 (breaking changes potentiels)
    }
  }
}
