output "project_id" {
  value       = module.vpc.project_id
  description = "VPC project id"
}

output "network" {
  value       = module.vpc
  description = "The created network"
}

output "network_name" {
  value       = module.vpc.network_name
  description = "The name of the VPC being created"
}

output "network_id" {
  value       = module.vpc.network_id
  description = "The ID of the VPC being created"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets."
}

output "subnets_names" {
  value       = module.vpc.subnets_names
  description = "The names of the subnets being created"
}

output "subnets_ids" {
  value       = module.vpc.subnets_ids
  description = "The IDs of the subnets being created"
}
