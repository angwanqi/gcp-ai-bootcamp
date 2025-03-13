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
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
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

# BQ reservations
resource "google_bigquery_reservation" "reservation" {
  name     = "${local.resource_prefix}-bq-reservation"
  location = local.region
  project  = local.project_id

  // Set to 0 for testing purposes
  // In reality this would be larger than zero
  slot_capacity     = 100
  edition           = "ENTERPRISE"
  ignore_idle_slots = true
  concurrency       = 0
  autoscale {
    max_slots = 100
  }
}

# create vertex AI workbench instance
resource "google_workbench_instance" "default" {
  count = 3

  name     = "${local.resource_prefix}-workbench-${count.index}"
  location = "${local.region}-${local.random_zone_list[count.index]}"
  project  = local.project_id

  instance_owners = local.project_users

  gce_setup {
    machine_type      = "e2-standard-8"
    disable_public_ip = true

    boot_disk {
      disk_size_gb = "150"
      disk_type    = "PD_BALANCED"
    }
    data_disks {
      disk_size_gb = "100"
      disk_type    = "PD_BALANCED"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      enable_vtpm                 = true
    }

    network_interfaces {
      network = local.vpc_id
      subnet  = "projects/${local.project_id}/regions/${local.region}/subnetworks/${local.region}"
    }
  }
}
