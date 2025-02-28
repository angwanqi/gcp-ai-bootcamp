terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "tenant" {
  source = "./modules/tenant"

  network_name   = "ai-takeoff-vpc"
  project_id     = var.project_id
  project_owners = var.project_owners
  region         = var.region
  resource_id    = var.resource_id

  services = [
    "iam.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "notebooks.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "aiplatform.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "artifactregistry.googleapis.com",
    "language.googleapis.com",
    "documentai.googleapis.com",
    "storage.googleapis.com",
    "discoveryengine.googleapis.com",
  ]

  subnets = [
    {
      subnet_name           = "sg-subnet"
      subnet_ip             = "10.10.0.0/16"
      subnet_region         = "asia-southeast1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "eu-subnet"
      subnet_ip             = "10.11.0.0/16"
      subnet_region         = "europe-west4"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "us-subnet"
      subnet_ip             = "10.12.0.0/16"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
    },
  ]
}


# # Grant project owner role to users
# resource "google_project_iam_member" "project_owners" {
#   for_each = toset(var.project_owners)

#   project = var.project_id
#   role    = "roles/owner"
#   member  = "user:${each.key}@example.com" # Replace with actual user emails
# }

# # Temp Vertex AI custom training Persistance Resource plan
# # This plan does not use any GPU, to be added
# # https://cloud.google.com/vertex-ai/docs/training/persistent-resource-create#create_a_persistent_resource
# resource "null_resource" "create_persistent_resource" {
#   provisioner "local-exec" {
#     command = <<EOT
#     gcloud ai persistent-resources create \
#     --persistent-resource-id=ai-take \
#     --display-name=ai-takeoff \
#     --project=fraud123-438914 \
#     --region=us-central1 \
#     --resource-pool-spec="replica-count=1,min-replica-count=1,max-replica-count=3,machine-type=n1-standard-4,disk-type=pd-ssd,disk-size=100"
#     EOT
#   }
# }
