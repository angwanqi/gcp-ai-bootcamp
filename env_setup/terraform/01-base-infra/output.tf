output "project_id" {
  value       = module.tenant.project_id
  description = "VPC project id"
}

output "vpc_id" {
  value       = module.tenant.vpc_id
  description = "VPC network id"
}

output "vpc_network_name" {
  value       = module.tenant.vpc_network_name
  description = "VPC network name"
}

output "vpc_subnet_ips" {
  value       = module.tenant.vpc_subnet_ips
  description = "VPC subnet ips"
}

output "project_users" {
  value       = var.project_users
  description = "list of project users"
}

output "region" {
  value       = var.region
  description = "region"
}

output "resource_prefix" {
  value       = var.resource_prefix
  description = "resource prefix"
}

output "random_region" {
  value       = random_shuffle.region.result[0]
  description = "random region"
}

output "random_zone" {
  value       = random_shuffle.zone.result[0]
  description = "random zone"
}

output "random_zone_list" {
  value       = random_shuffle.zone.result
  description = "random zone list"
}

