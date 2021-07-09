variable "account_id" { type = string }
variable "display_name" { type = string }

resource "google_service_account" "env" {
  account_id   = var.account_id
  display_name = var.display_name
}

output "email" {
  value = google_service_account.env.email
}

