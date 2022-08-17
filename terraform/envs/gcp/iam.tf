locals {
  tf_github_actions_account_roles = toset([
    "roles/compute.viewer",
  ])
}

resource "google_service_account" "tf_github_actions_account" {
  account_id   = "tf-github-actions-account"
  display_name = "tf-github-actions-account"
}

resource "google_project_iam_member" "tf_github_actions_account_role_binding" {
  for_each = local.tf_github_actions_account_roles
  project  = var.gcp_project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.tf_github_actions_account.email}"
}

resource "google_iam_workload_identity_pool" "tf_github_actions_pool" {
  provider                  = google-beta
  workload_identity_pool_id = "tf-github-actions-pool"
}

resource "google_iam_workload_identity_pool_provider" "tf_github_actions_pool_provider" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.tf_github_actions_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "tf-github-actions-pool-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.aud"        = "assertion.aud"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "user_panel_dev_gha_pool_impersonation" {
  provider           = google-beta
  service_account_id = google_service_account.tf_github_actions_account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tf_github_actions_pool.name}/attribute.repository/${var.github_repository}"
}
