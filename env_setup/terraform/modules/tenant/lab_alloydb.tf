# resources required for alloydb lab

locals {
  alloydb_lab_services = [
    "servicenetworking.googleapis.com",
    "alloydb.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
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
resource "google_compute_global_address" "alloydb_range" {
  name    = "${var.resource_prefix}-alloydb-range"
  purpose = "VPC_PEERING"

  project       = var.project_id
  address       = var.alloydb_psa_subnet_ip
  prefix_length = 24
  address_type  = "INTERNAL"
  network       = module.vpc.network_id

  depends_on = [google_project_service.alloydb_lab_services]
}

# create service connection
resource "google_service_networking_connection" "alloydb_vpc_connection" {
  network = module.vpc.network_id
  service = "servicenetworking.googleapis.com"

  reserved_peering_ranges = [google_compute_global_address.alloydb_range.name]
}

# create alloydb cluster
resource "google_alloydb_cluster" "alloydb_cluster" {
  provider   = google-beta # alloydb_cluster requires the beta provider
  project    = var.project_id
  location   = var.region
  cluster_id = "${var.resource_prefix}-alloydb-cluster"

  network_config {
    network = module.vpc.network_id
  }
  depends_on = [
    google_service_networking_connection.alloydb_vpc_connection
  ]
}

# Create alloydb instance
resource "google_alloydb_instance" "alloydb_instance" {
  provider      = google-beta
  cluster       = google_alloydb_cluster.alloydb_cluster.name
  instance_id   = "${var.resource_prefix}-alloydb-instance" # Replace with your desired instance ID
  instance_type = "PRIMARY"                                 # Other types are: READ_POOL

  database_flags = {
    "password.enforce_complexity" = "on" # required for public IP access
  }

  #availability_type = "REGIONAL" # uncomment to set availability_type
  network_config {
    enable_public_ip = true
  }

  machine_config {
    cpu_count = 4 # min 2 CPU
  }

  depends_on = [
    google_alloydb_cluster.alloydb_cluster
  ]
}

# Allow traffic to AlloyDB instances from within the VPC
resource "google_compute_firewall" "alloydb_allow_internal" {
  name    = "${var.resource_prefix}-alloydb-allow-internal-rule"
  network = module.vpc.network_id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["5432"] # Default AlloyDB port
  }

  # Allow access from within the VPC
  source_ranges = module.vpc.subnets_ips
  description   = "Allow TCP traffic on port 5432 to AlloyDB from within the VPC"
  depends_on = [
    google_alloydb_instance.alloydb_instance
  ]
}
