# ---------------------------------------------------------------------------
# Outputs du module VPC : ce que le module expose aux appelants
# (environments/dev/main.tf va lire module.vpc.vpc_id, etc.)
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés"
  value       = [for s in aws_subnet.private : s.id]
}

output "vpc_cidr_block" {
  description = "Bloc CIDR du VPC"
  value       = aws_vpc.main.cidr_block
}
