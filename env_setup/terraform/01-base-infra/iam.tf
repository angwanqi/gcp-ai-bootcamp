locals {
  user_list = formatlist("user:%s", var.project_users)
}

# project owners - to tighten if schedule permits
resource "google_project_iam_binding" "project_owners" {
  project  = var.project_id
  role     = "roles/owner"

  members = local.user_list
}
