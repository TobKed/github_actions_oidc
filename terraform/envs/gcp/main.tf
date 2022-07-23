locals {
  services = [
    "servicecontrol.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "servicemanagement.googleapis.com",
    "storage-api.googleapis.com",
  ]
}

resource "google_project_service" "default" {
  for_each = toset(local.services)

  project = var.gcp_project_id
  service = each.value

  disable_on_destroy = false
}

data "google_project" "project" {}
