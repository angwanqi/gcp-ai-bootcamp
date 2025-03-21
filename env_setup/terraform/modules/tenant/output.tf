output "project_id" {
  value       = module.vpc.project_id
  description = "VPC project id"
}

output "vpc_id" {
  value       = module.vpc.network_id
  description = "VPC network id"
}

output "vpc_network_name" {
  value       = module.vpc.network_name
  description = "VPC network name"
}

output "vpc_subnet_ips" {
  value       = module.vpc.subnets_ips
  description = "VPC subnet ips"
}
