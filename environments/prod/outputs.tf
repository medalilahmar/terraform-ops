output "vpc_id" {
  value = module.vpc.vpc_id
}

output "app_instance_ids" {
  value = module.app_servers.instance_ids
}

output "app_private_ips" {
  value = module.app_servers.private_ips
}
