terraform {
  backend "gcs" {
    bucket = "ga-oidc-test-bis-tf"
    prefix = "terraform_state/github/TobKed/github_actions_oidc/terraform.tfstate"
  }
}
