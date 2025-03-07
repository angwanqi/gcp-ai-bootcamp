# resources required for alloydb lab

locals {
  alloydb_lab_services = [
    "alloydb.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "networkconnectivity.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

# enable APIs
resource "google_project_service" "alloydb_lab_services" {
  for_each = toset(local.alloydb_lab_services)
  service  = each.value

  project = var.project_id

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
  disable_on_destroy         = false
}

# allocate private connect address for alloydb
resource "google_compute_global_address" "alloydb_private_range" {
  name         = "${var.resource_prefix}-alloydb-range"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING"

  network       = module.vpc.network_name
  address       = split("/", var.alloydb_psa_subnet)[0]
  prefix_length = split("/", var.alloydb_psa_subnet)[1]

  depends_on = [google_project_service.alloydb_lab_services]
}

# create service connection
resource "google_service_networking_connection" "alloydb_vpc_connection" {
  network = module.vpc.network_id
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.alloydb_private_range.name]
}

# Import or export custom routes
resource "google_compute_network_peering_routes_config" "alloydb_peering_routes" {
  project = var.project_id

  peering = google_service_networking_connection.alloydb_vpc_connection.peering
  network = module.vpc.network_name

  import_custom_routes = true
  export_custom_routes = true
}

# # create alloydb cluster
# resource "google_alloydb_cluster" "alloydb_cluster" {
#   provider   = google-beta # alloydb_cluster requires the beta provider
#   project    = var.project_id
#   location   = var.region
#   cluster_id = "${var.resource_prefix}-alloydb-cluster"

#   initial_user {
#     user     = var.alloydb_initial_user
#     password = var.alloydb_initial_password
#   }

#   network_config {
#     network = module.vpc.network_name
#   }

#   continuous_backup_config {
#     enabled              = true
#     recovery_window_days = 14
#   }

#   automated_backup_policy {
#     location      = var.region
#     backup_window = "3600s"
#     enabled       = false

#     weekly_schedule {
#       days_of_week = ["MONDAY"]

#       start_times {
#         hours   = 23
#         minutes = 0
#         seconds = 0
#         nanos   = 0
#       }
#     }
#   }

#   depends_on = [
#     google_service_networking_connection.alloydb_vpc_connection
#   ]
# }

# # Create alloydb instance
# resource "google_alloydb_instance" "alloydb_instance" {
#   provider    = google-beta
#   cluster     = google_alloydb_cluster.alloydb_cluster.name
#   instance_id = "${var.resource_prefix}-alloydb-cluster-primary" # Replace with your desired instance ID

#   instance_type     = "PRIMARY"  # Other types are: READ_POOL
#   availability_type = "ZONAL"    # Available options: REGIONAL, ZONAL

#   # database_flags = {
#   #   "password.enforce_complexity"                         = "on" # required for public IP access
#   #   "password.enforce_expiration"                         = "on"
#   #   "password.enforce_password_does_not_contain_username" = "off"
#   #   "password.min_lowercase_letters"                      = "1"
#   #   "password.min_uppercase_letters"                      = "1"
#   #   "password.min_numerical_chars"                        = "1"
#   #   "password.min_special_chars"                          = "1"
#   #   "password.min_pass_length"                            = "10"
#   # }

#   # network_config {
#   #   enable_public_ip = true
#   # }

#   machine_config {
#     cpu_count = 4 # min 2 CPU
#   }

#   depends_on = [
#     google_service_networking_connection.alloydb_vpc_connection
#   ]
# }

# # Allow traffic to AlloyDB instances from within the VPC
# resource "google_compute_firewall" "alloydb_allow_internal" {
#   name    = "${var.resource_prefix}-alloydb-allow-internal-rule"
#   network = module.vpc.network_id
#   project = var.project_id

#   # Allow access from within the VPC
#   source_ranges = module.vpc.subnets_ips
#   description   = "Allow TCP traffic on port 5432 to AlloyDB from within the VPC"

#   allow {
#     protocol = "tcp"
#     ports    = ["5432"] # Default AlloyDB port
#   }
#   direction = "EGRESS"
# }

# # Allow project users to access AlloyDB instance
# resource "google_alloydb_user" "alloydb_user" {
#   for_each = toset(var.project_users)

#   cluster   = google_alloydb_cluster.alloydb_cluster.name
#   user_id   = each.key
#   user_type = "ALLOYDB_IAM_USER"

#   database_roles = ["alloydbsuperuser"]
#   depends_on     = [google_alloydb_instance.alloydb_instance]
# }

