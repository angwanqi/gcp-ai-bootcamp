# resources required for alloydb lab
data "terraform_remote_state" "base_infra" {
  backend = "local"

  config = {
    path = "../01-base-infra/terraform.tfstate"
  }
}

locals {
  project_id = data.terraform_remote_state.base_infra.outputs.project_id
  region     = data.terraform_remote_state.base_infra.outputs.region

  vpc_id           = data.terraform_remote_state.base_infra.outputs.vpc_id
  vpc_network_name = data.terraform_remote_state.base_infra.outputs.vpc_network_name
  vpc_subnet_ips   = data.terraform_remote_state.base_infra.outputs.vpc_subnet_ips

  random_region    = data.terraform_remote_state.base_infra.outputs.random_region
  random_zone_list = data.terraform_remote_state.base_infra.outputs.random_zone_list

  resource_prefix = data.terraform_remote_state.base_infra.outputs.resource_prefix
  project_users   = data.terraform_remote_state.base_infra.outputs.project_users

  lab_services = [
    "alloydb.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "networkconnectivity.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

provider "google" {
  project = local.project_id
  region  = local.region
}

provider "google-beta" {
  project = local.project_id
  region  = local.region
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

# allocate private connect address for alloydb
resource "google_compute_global_address" "alloydb_private_range" {
  project      = local.project_id
  name         = "${local.resource_prefix}-alloydb-range"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING"

  network       = local.vpc_network_name
  address       = split("/", var.alloydb_psa_subnet)[0]
  prefix_length = split("/", var.alloydb_psa_subnet)[1]

  depends_on = [google_project_service.lab_services]
}

# create service connection
resource "google_service_networking_connection" "alloydb_vpc_connection" {
  network = local.vpc_network_name
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.alloydb_private_range.name]
}

# Import or export custom routes
resource "google_compute_network_peering_routes_config" "alloydb_peering_routes" {
  project = local.project_id

  peering = google_service_networking_connection.alloydb_vpc_connection.peering
  network = local.vpc_network_name

  import_custom_routes = true
  export_custom_routes = true
}

# create alloydb cluster
resource "google_alloydb_cluster" "alloydb_cluster" {
  provider   = google-beta # alloydb_cluster requires the beta provider
  project    = local.project_id
  location   = local.region
  cluster_id = "${local.resource_prefix}-alloydb-cluster"

  initial_user {
    user     = var.alloydb_initial_user
    password = var.alloydb_initial_password
  }

  network_config {
    network = local.vpc_network_name
  }

  continuous_backup_config {
    enabled              = true
    recovery_window_days = 14
  }

  automated_backup_policy {
    location      = local.region
    backup_window = "3600s"
    enabled       = false

    weekly_schedule {
      days_of_week = ["MONDAY"]

      start_times {
        hours   = 23
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  depends_on = [
    google_service_networking_connection.alloydb_vpc_connection
  ]
}

# Create alloydb instance
resource "google_alloydb_instance" "alloydb_instance" {
  provider    = google-beta
  cluster     = google_alloydb_cluster.alloydb_cluster.name
  instance_id = "${local.resource_prefix}-alloydb-cluster-primary" # Replace with your desired instance ID

  instance_type     = "PRIMARY" # Other types are: READ_POOL
  availability_type = "ZONAL"   # Available options: REGIONAL, ZONAL

  # database_flags = {
  #   "password.enforce_complexity"                         = "on" # required for public IP access
  #   "password.enforce_expiration"                         = "on"
  #   "password.enforce_password_does_not_contain_username" = "off"
  #   "password.min_lowercase_letters"                      = "1"
  #   "password.min_uppercase_letters"                      = "1"
  #   "password.min_numerical_chars"                        = "1"
  #   "password.min_special_chars"                          = "1"
  #   "password.min_pass_length"                            = "10"
  # }

  # network_config {
  #   enable_public_ip = true
  # }

  machine_config {
    cpu_count = 4 # min 2 CPU
  }

  depends_on = [
    google_service_networking_connection.alloydb_vpc_connection
  ]
}

# Allow traffic to AlloyDB instances from within the VPC
resource "google_compute_firewall" "alloydb_allow_internal" {
  name    = "${local.resource_prefix}-alloydb-allow-internal-rule"
  network = local.vpc_id
  project = local.project_id

  # Allow access from within the VPC
  source_ranges = local.vpc_subnet_ips
  description   = "Allow TCP traffic on port 5432 to AlloyDB from within the VPC"

  allow {
    protocol = "tcp"
    ports    = ["5432"] # Default AlloyDB port
  }
  direction = "EGRESS"
}

# Allow project users to access AlloyDB instance
resource "google_alloydb_user" "alloydb_user" {
  for_each = toset(local.project_users)

  cluster   = google_alloydb_cluster.alloydb_cluster.name
  user_id   = each.key
  user_type = "ALLOYDB_IAM_USER"

  database_roles = ["alloydbsuperuser"]
  depends_on     = [google_alloydb_instance.alloydb_instance]
}
