variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
}

variable "region" {
  type        = string
  description = "The region for the Google Cloud project resources"
  default     = "europe-west4" # Set a default region
}

variable "billing_account" {
  type        = string
  description = "The billing account ID for the Google Cloud project"
}

variable "project_owners" {
  type        = set(string)
  description = "A set of usernames to be granted the project owner role"
  default     = [] # Set an empty set as default
}

variable "resource_id" {
  type        = string
  description = "The default ID for shared resources"
  default     = "ai-takeoff"
}

# variable "domain_name" {
#   type = string
#   description = "The domain name for the user email addresses"
# }
