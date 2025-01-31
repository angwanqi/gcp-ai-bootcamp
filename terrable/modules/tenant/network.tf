locals {
  subnets = setunion(var.subnets, var.shared_vpc_host == true ? var.shared_vpc_subnets : [])

  # this creates a map of unique subnet regions from the map of subnets
  subnets_regions = {
    for x in local.subnets :
    "${x.subnet_region}" => x...
  }
}

data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

# create dedicated VPC for project
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.3"

  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = var.routing_mode

  auto_create_subnetworks = var.auto_create_subnetworks
  shared_vpc_host         = var.shared_vpc_host

  subnets          = local.subnets
  secondary_ranges = var.secondary_ranges

  routes         = var.routes
  firewall_rules = var.firewall_rules
}

# allow iap so we can access the compute instances
resource "google_compute_firewall" "allow_iap" {
  name    = "${module.vpc.network_name}-allow-ingress-from-iap-rule"
  project = var.project_id
  network = module.vpc.network_name

  source_ranges = concat(data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# create a router per region
resource "google_compute_router" "router" {
  for_each = local.subnets_regions
  name     = "${module.vpc.network_name}-${each.key}-router"
  project  = var.project_id

  region  = each.key
  network = module.vpc.network_id

  bgp {
    asn = 64514
  }
}

# create a nat per region
resource "google_compute_router_nat" "nat" {
  for_each = local.subnets_regions
  name     = "${module.vpc.network_name}-${each.key}-nat"
  project  = var.project_id

  router                             = "${module.vpc.network_name}-${each.key}-router"
  region                             = each.key
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.router]
}
