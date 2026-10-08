provider "aws" {
  region = var.aws_region

  # Tags par défaut appliqués automatiquement à TOUTES les ressources AWS
  # du provider -> évite d'oublier de tagger une ressource (bonne pratique)
  default_tags {
    tags = {
      Project   = "myapp"
      ManagedBy = "terraform"
      Environment = var.environment
    }
  }
}
