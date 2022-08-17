output "gcp_project_id" {
  description = "GCP_PROJECT_ID"
  value       = var.gcp_project_id
}
output "gcp_project_number" {
  description = "GCP_PROJECT_NUMBER"
  value       = data.google_project.project.number
}

output "gcp_service_account" {
  description = "GCP_SERVICE_ACCOUNT"
  value       = google_service_account.tf_github_actions_account.email

}
output "gcp_identity_pool" {
  description = "GCP_IDENTITY_POOL"
  value       = google_iam_workload_identity_pool.tf_github_actions_pool.name
}

output "gcp_identity_pool_provider" {
  description = "GCP_IDENTITY_POOL_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.tf_github_actions_pool_provider.name
}
