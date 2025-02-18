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
