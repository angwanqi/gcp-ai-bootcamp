# project owners - to tighten if schedule permits
resource "google_project_iam_binding" "project_owners" {
  for_each = toset(var.project_users)
  project  = var.project_id
  role     = "roles/owner"

  members = [
    "user:${each.key}"
  ]
}
