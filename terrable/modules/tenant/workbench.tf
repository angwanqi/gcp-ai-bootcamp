#resource "google_service_account" "workbench_sa" {
#  account_id   = "vertex-ai-workbench-sa"
#  display_name = "Vertex AI Workbench Service Account"
#  project      = var.project_id
#}

resource "random_shuffle" "workbench_zone" {
  input = [format("%s-%s", var.region, "a"), format("%s-%s", var.region, "b"), format("%s-%s", var.region, "c")]
}

module "vertex_ai_workbench" {
  source = "GoogleCloudPlatform/vertex-ai/google//modules/workbench"

  name       = var.resource_id
  location   = random_shuffle.workbench_zone.result[0]
  project_id = var.project_id

  machine_type  = "e2-standard-8"
  desired_state = "ACTIVE"

  labels = {
    env  = "dev"
    type = "workbench"
  }

#  service_accounts = [
#    {
#      email = google_service_account.workbench_sa.email
#    },
#  ]

  data_disks = [
    {
      disk_size_gb = 330
      disk_type    = "PD_BALANCED"
    },
  ]

  network_interfaces = [
    {
      network  = module.vpc.network_id
      subnet   = module.vpc.subnets_ids[index(module.vpc.subnets_regions, "${var.region}")]
      nic_type = "GVNIC"
    }
  ]

  ## https://cloud.google.com/vertex-ai/docs/workbench/instances/manage-metadata
  metadata_configs = {
    idle-timeout-seconds = 86400
  }

  shielded_instance_config = {
    enable_secure_boot = true
  }
}
