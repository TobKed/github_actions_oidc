# Example of GitHub Actions workflow with OIDC authentication to Google Cloud Platform

Easy to follow shell commands to set up Google Cloud Platform [GCP] resources working with simple
GitHub Actions [GA] workflow using OIDC to authenticate to GCP.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [GCP Instructions](#gcp-instructions)
- [Links](#links)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## GCP Instructions

1. Exports

    ```sh
    export PROJECT_ID=ga-oidc-test-bis
    export SERVICE_ACCOUNT_NAME=my-service-account
    export WORKLOAD_IDENTITY_POOL=github-actions-pool
    export WORKLOAD_IDENTITY_POOL_DISPLAY_NAME="GitHub Actions pool"
    export WORKLOAD_IDENTITY_POOL_PROVIDER=github-actions-pool-provider
    export WORKLOAD_IDENTITY_POOL_PROVIDER_DISPLAY_NAME="Github Actions Pool provider"
    export REPOSITORY="TobKed/github_actions_oidc"

    export SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    export PROJECT_NUMBER=$(gcloud projects list \
      --format="value(projectNumber)" \
      --filter="projectId=${PROJECT_ID}")
   ```
1. Service Account:

    ```sh
    gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
        --project "${PROJECT_ID}"
    ```
1. Enable IAM API:

    ```sh
    gcloud services enable iamcredentials.googleapis.com \
      --project "${PROJECT_ID}"
    ```
1. Example of enabling resources API and IAM access (required for listing Google Cloud Compute [GCE] instances in GA workflow)

    ```sh
    gcloud services enable compute.googleapis.com \
      --project "${PROJECT_ID}"
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
      --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
      --role=roles/compute.viewer
    ```

1. Create workload identity pool and provider:

    ```sh
    gcloud iam workload-identity-pools create "${WORKLOAD_IDENTITY_POOL}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --display-name="${WORKLOAD_IDENTITY_POOL_DISPLAY_NAME}"

    export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "${WORKLOAD_IDENTITY_POOL}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --format="value(name)")

    gcloud iam workload-identity-pools providers create-oidc "${WORKLOAD_IDENTITY_POOL_PROVIDER}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
      --display-name="${WORKLOAD_IDENTITY_POOL_PROVIDER_DISPLAY_NAME}" \
      --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.aud=assertion.aud" \
      --issuer-uri="https://token.actions.githubusercontent.com"
    ```

    Not all attributes from `--attribute-mapping` are used and may be deleted, added more to show possiblities.

1. Example of attribute condition for additional security (`--attribute-condition` argument may be used in previous step as well):

    ```sh
    gcloud iam workload-identity-pools providers update-oidc "${WORKLOAD_IDENTITY_POOL_PROVIDER}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
      --attribute-condition="(assertion.sub=='repo:${REPOSITORY}:ref:refs/heads/master')"
    ```

    Filters workflow only to `master` branch.

1. Allow Service Account authentication:

    to specific repo:

    ```sh
    gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
      --project="${PROJECT_ID}" \
      --role="roles/iam.workloadIdentityUser" \
      --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPOSITORY}"
    ```

    or more general:

    ```sh
    gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_EMAIL}" \
      --project="${PROJECT_ID}" \
      --role="roles/iam.workloadIdentityUser" \
      --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/*"
    ```

## Links

 - [The GitHub Blog: GitHub Actions: Secure cloud deployments with OpenID Connect](https://github.blog/changelog/2021-10-27-github-actions-secure-cloud-deployments-with-openid-connect/)
 - [GitHub Docs - About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
 - GCP:
   - [GitHub Docs - Configuring OpenID Connect in Google Cloud Platform](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)
   - [Google Cloud - Workload identity federation](https://cloud.google.com/iam/docs/workload-identity-federation)
   - [Google Cloud - Configuring workload identity federation](https://cloud.google.com/iam/docs/configuring-workload-identity-federation#github-actions_2)
   - [`google-github-actions/auth` - Authenticating via Workload Identity Federation](https://github.com/google-github-actions/auth#authenticating-via-workload-identity-federation-1)
   - [`google-github-actions/auth` - Setting up Workload Identity Federation](https://github.com/google-github-actions/auth/tree/v0.4.0#setting-up-workload-identity-federation)
   - [Google Cloud Console - Workload Identity Pools ](https://console.cloud.google.com/iam-admin/workload-identity-pools)
 - AWS:
   - []()
   - []()
   - []()
