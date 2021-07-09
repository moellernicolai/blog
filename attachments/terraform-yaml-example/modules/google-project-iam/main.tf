variable "project" { type = string }
variable "role" { type = string }
variable "email" { type = string }

resource "google_project_iam_member" "env" {
  project = var.project
  role    = var.role
  member  = "serviceAccount:${var.email}"
}

