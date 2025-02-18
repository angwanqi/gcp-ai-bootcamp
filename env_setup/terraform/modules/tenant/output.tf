output "project_id" {
  value       = module.vpc.project_id
  description = "VPC project id"
}

output "vpc_id" {
  value       = module.vpc.network_id
  description = "VPC network id"
}