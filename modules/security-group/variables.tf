variable "environment" {
  description = "Nom de l'environnement"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC dans lequel créer le security group"
  type        = string
}

variable "name" {
  description = "Nom logique du security group"
  type        = string
}

# object() avec attributs typés : plus strict/sûr qu'une simple liste de maps
variable "ingress_rules" {
  description = "Liste des règles entrantes à autoriser"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
