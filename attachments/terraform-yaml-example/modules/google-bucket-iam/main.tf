variable "bucket" { type = string }
variable "role" { type = string }
variable "email" { type = string }

resource "google_storage_bucket_iam_member" "env" {
  bucket = var.bucket
  role   = var.role
  member = "serviceAccount:${var.email}"
}

