# enable APIs
resource "google_project_service" "services" {
  for_each = var.services
  service  = each.value

  project = var.project_id

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
  disable_on_destroy         = false
}

# add the project owners
resource "google_project_iam_member" "owners" {
  for_each = toset(var.project_owners)

  project = var.project_id
  role    = "roles/owner"
  member  = "user:${each.key}"
}

# # ensure the binding 
# resource "google_project_iam_binding" "owners" {
#   for_each = toset(var.project_owners)

#   project = var.project_id
#   role    = "roles/owner"
#   members = [
#     "user:${each.key}"
#   ]
# }

module "cli" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.0"

  platform              = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint = "${path.module}/scripts/persistent-resource.sh"
  create_cmd_body       = "create ${var.project_id} ${var.region} ${var.resource_id}"

  destroy_cmd_entrypoint = "${path.module}/scripts/persistent-resource.sh"
  destroy_cmd_body       = "delete ${var.project_id} ${var.region} ${var.resource_id}"

  #  depends_on = [google_project_service.services]
}

# BQ reservations
resource "google_bigquery_reservation" "reservation" {
  name     = var.resource_id
  location = var.region

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

#resource "google_service_account" "default" {
#  account_id   = "lab-sa"
#  display_name = "Custom SA for VM Instance"
#}

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "n1-standard-4"
  zone         = random_shuffle.workbench_zone.result[0]

  tags = ["lab"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    subnetwork = module.vpc.subnets_ids[index(module.vpc.subnets_regions, "${var.region}")]
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

#  service_account {
#    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#    email  = google_service_account.default.email
#    scopes = ["cloud-platform"]
#  }
}
