
resource "random_shuffle" "region" {
  input        = ["us-central1", "europe-west4", "asia-southeast1"]
  result_count = 1
}

resource "random_shuffle" "zone" {
  input        = ["a", "b", "c"]
  result_count = 3
}

module "tenant" {
  source = "./modules/tenant"

  network_name = "${var.resource_prefix}-vpc"
  project_id   = var.project_id
  region       = var.region

  project_users   = var.project_users
  resource_prefix = var.resource_prefix

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
      subnet_name           = "asia-southeast1"
      subnet_ip             = "10.10.0.0/16"
      subnet_region         = "asia-southeast1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "europe-west4"
      subnet_ip             = "10.11.0.0/16"
      subnet_region         = "europe-west4"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "us-central1"
      subnet_ip             = "10.12.0.0/16"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
    },
  ]
}
