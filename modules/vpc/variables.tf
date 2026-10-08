# ---------------------------------------------------------------------------
# Variables du module VPC
# Bonne pratique : toujours typer + décrire + valider quand c'est pertinent
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod). Utilisé pour le nommage et le tagging."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être l'un de : dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC, ex: 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

# map(string) : une bonne pratique pour piloter for_each avec des clés nommées
# plutôt qu'une simple liste (voir README section 3 : count vs for_each)
variable "public_subnets" {
  description = "Map des subnets publics : clé = nom logique, valeur = CIDR"
  type        = map(string)
  default = {
    "public-a" = "10.0.1.0/24"
    "public-b" = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  description = "Map des subnets privés : clé = nom logique, valeur = CIDR"
  type        = map(string)
  default = {
    "private-a" = "10.0.101.0/24"
    "private-b" = "10.0.102.0/24"
  }
}

variable "enable_nat_gateway" {
  description = "Active un NAT Gateway pour donner un accès internet sortant aux subnets privés (coûte de l'argent -> souvent false en dev)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags communs à appliquer à toutes les ressources du module"
  type        = map(string)
  default     = {}
}
