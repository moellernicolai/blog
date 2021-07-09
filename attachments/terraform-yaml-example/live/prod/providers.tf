provider "google" {
  project = local.config.gcpProvider.project
  region  = local.config.gcpProvider.region
}

