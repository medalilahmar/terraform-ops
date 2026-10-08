variable "environment" {
  type = string
}

variable "instance_count" {
  description = "Nombre d'instances EC2 à créer (exemple d'usage de count)"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 5
    error_message = "instance_count doit être compris entre 1 et 5."
  }
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "Liste des subnets où placer les instances (on boucle dessus avec count)"
  type        = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "enable_detailed_monitoring" {
  description = "Exemple de flag conditionnel (expression ternaire dans main.tf)"
  type        = bool
  default     = false
}

# Exemple de bonne pratique : secret jamais en clair, marqué sensitive.
# En pratique la valeur serait injectée via TF_VAR_db_password ou récupérée
# depuis AWS Secrets Manager (data "aws_secretsmanager_secret_version").
variable "db_password" {
  description = "Mot de passe applicatif transmis en userdata (exemple pédagogique)"
  type        = string
  default     = "changeme-in-real-usage"
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
