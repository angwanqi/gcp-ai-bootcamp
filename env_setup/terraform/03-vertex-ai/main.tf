data "terraform_remote_state" "base_infra" {
  backend = "local"

  config = {
    path = "../01-base-infra/terraform.tfstate"
  }
}

locals {
  project_id = data.terraform_remote_state.base_infra.outputs.project_id
  region     = data.terraform_remote_state.base_infra.outputs.region
  vpc_id     = data.terraform_remote_state.base_infra.outputs.vpc_id

  random_region    = data.terraform_remote_state.base_infra.outputs.random_region
  random_zone_list = data.terraform_remote_state.base_infra.outputs.random_zone_list

  resource_prefix = data.terraform_remote_state.base_infra.outputs.resource_prefix
  project_users   = data.terraform_remote_state.base_infra.outputs.project_users

  lab_services = [
    "notebooks.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "aiplatform.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "ml.googleapis.com",
    "dialogflow.googleapis.com",
  ]
}

# enable APIs
resource "google_project_service" "lab_services" {
  for_each = toset(local.lab_services)
  service  = each.value

  project = local.project_id

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Vertex AI persistent resource via gcloud cli
module "cli" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.0"
  
  platform = "linux"

  create_cmd_entrypoint = "${path.module}/scripts/persistent-resource.sh"
  create_cmd_body       = "create ${local.project_id} ${local.region} ${local.resource_prefix}"

  destroy_cmd_entrypoint = "${path.module}/scripts/persistent-resource.sh"
  destroy_cmd_body       = "delete ${local.project_id} ${local.region} ${local.resource_prefix}"
}
