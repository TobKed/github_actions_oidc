terraform {
  required_version = ">= 1.2.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.29.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.29.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
}

provider "google-beta" {
  project = var.gcp_project_id
}
