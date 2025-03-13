variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
}

variable "region" {
  type        = string
  description = "The region for the Google Cloud project resources"
  default     = "asia-southeast1" # Set a default region
}

variable "resource_prefix" {
  type        = string
  description = "The default ID for shared resources"
  default     = "ai-takeoff"
}

variable "project_users" {
  type        = set(string)
  description = "A set of usernames to be granted the project roles"
  default     = [] # Set an empty set as default
}

# lab specific variables
variable "alloydb_initial_user" {
  type        = string
  description = "AlloyDB initial user"
  default     = "alloydbadmin"
}

variable "alloydb_initial_password" {
  type        = string
  description = "AlloyDB initial password"
}
