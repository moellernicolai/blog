module "service-account" {
  source = "../../modules/google-service-account"
  for_each = {
    for sa in local.config.serviceAccounts : sa.name => ""
  }

  account_id   = each.key
  display_name = "Service account created via Terraform"
}

module "project-iam" {
  source = "../../modules/google-project-iam"
  for_each = {
    for k, v in local.iam : k => v
    if v.type == "project"
  }

  project = each.value.name
  role    = each.value.role
  email   = module.service-account[each.value.sa].email
}

module "bucket-iam" {
  source = "../../modules/google-bucket-iam"
  for_each = {
    for k, v in local.iam : k => v
    if v.type == "bucket"
  }

  bucket = each.value.name
  role   = each.value.role
  email  = module.service-account[each.value.sa].email
}

