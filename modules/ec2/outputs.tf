output "instance_ids" {
  description = "Liste des IDs des instances EC2 créées"
  value       = aws_instance.app[*].id
  # aws_instance.app[*].id : le "splat operator", équivalent de
  # [for i in aws_instance.app : i.id]
}

output "private_ips" {
  description = "Adresses IP privées des instances"
  value       = aws_instance.app[*].private_ip
}
