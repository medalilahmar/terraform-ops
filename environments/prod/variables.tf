variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.medium" # plus puissant qu'en dev
}

variable "instance_count" {
  type    = number
  default = 4 # plus d'instances qu'en dev pour la haute disponibilité
}

variable "db_password" {
  type      = string
  sensitive = true
  # Pas de default ici volontairement : on force à la passer via
  # terraform.tfvars (gitignoré) ou TF_VAR_db_password
}
