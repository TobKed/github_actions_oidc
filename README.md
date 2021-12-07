# Example of GitHub Actions workflow with OpenID Connect authentication to Google Cloud Platform and Amazon Web Services

[![pre-commit](https://github.com/TobKed/github_actions_oidc/actions/workflows/ci.yaml/badge.svg)](https://github.com/TobKed/github_actions_oidc/actions/workflows/ci.yaml)
[![GCP example workflow](https://github.com/TobKed/github_actions_oidc/actions/workflows/gcp.yaml/badge.svg)](https://github.com/TobKed/github_actions_oidc/actions/workflows/gcp.yaml)
[![AWS example workflow](https://github.com/TobKed/github_actions_oidc/actions/workflows/aws.yaml/badge.svg)](https://github.com/TobKed/github_actions_oidc/actions/workflows/aws.yaml)

Easy to follow shell commands to set up Google Cloud Platform [GCP] and Amazon Web Services [AWS]
resources working with simple GitHub Actions [GA] workflow using OpenID Connect [OIDC] to authenticate.

The OIDC gives more granular control over authentication, authorization and credentials rotation.
Any long-lived credentials also do not have to be stored as GitHub Secrets.

Read more on [GitHub Docs - About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [GitHub Actions permissions](#github-actions-permissions)
- [GCP Instructions](#gcp-instructions)
- [AWS Instructions](#aws-instructions)
- [Links](#links)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## GitHub Actions permissions

When you use OIDC in GA workflows remember to grand `id-token: write` permission.

```yaml
permissions:
  id-token: write
```

It can be set on top-level or for specific jobs.
Important: if you specify the access for any of permssiion scopes, all of those that are not specified are set to none.

Read more about permissions:

 - [Permissions for the ``GITHUB_TOKEN``](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
 - [Workflow syntax fot GitHub Actions - permissions](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions#permissions)

## GCP Instructions

1. Prerequisites:

   - installed and configured [`gcloud` cli](https://cloud.google.com/sdk/gcloud/).
   - edited file [`.github/workflows/gcp.yaml`](.github/workflows/gcp.yaml) for your project

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
1. Create Service Account:

    ```sh
    gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
        --project "${PROJECT_ID}"
    ```
1. Enable IAM API:

    ```sh
    gcloud services enable iamcredentials.googleapis.com \
      --project "${PROJECT_ID}"
    ```
1. An example of enabling resources API and IAM access (required for listing Google Cloud Compute [GCE] instances in GA workflow):

    ```sh
    gcloud services enable compute.googleapis.com \
      --project "${PROJECT_ID}"
    gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
      --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
      --role=roles/compute.viewer
    ```

1. Create the workload identity pool and provider:

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

    Not all attributes from `--attribute-mapping` parameter are used and may be adjusted. Just added more to show possibilities.

1. An example of attribute condition for additional security (`--attribute-condition` argument may be used in the previous step as well):

    ```sh
    gcloud iam workload-identity-pools providers update-oidc "${WORKLOAD_IDENTITY_POOL_PROVIDER}" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
      --attribute-condition="(assertion.sub=='repo:${REPOSITORY}:ref:refs/heads/master')"
    ```

    It filters workflow only to the `master` branch.

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

## AWS Instructions

1. Prerequisites:

   - installed and configured [`aws cli`](https://aws.amazon.com/cli/)
   - installed  openssl
   - example workflow copies `README.md` to s3 bucket, you may need one
   - edited files [`.github/workflows/aws.yaml`](.github/workflows/aws.yaml),
     [`aws_bucket_policy.json`](aws_bucket_policy.json) and [`aws_role_for_ga.json`](aws_role_for_ga.json)
     for your project

1. Exports

   ```sh
   export ROLE_NAME=RoleForGitHubActions

   export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
   ```

1. Get OpenID Connect Identity Provider [IdP] thumbprint:

   ```sh
   export OIDC_IDP_THUMBPRINT=$(
     echo 1 | \
     openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 2>/dev/null \
     | sed -n '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' \
     | sed -n '/END CERTIFICATE/,$ p' \
     | tail -n +2 \
     | openssl x509 -fingerprint -noout \
     | sed -e 's/^SHA1\ Fingerprint=//' | \
     sed -e 's/://g'
   )
   ```

   Based on [AWS - Obtaining the thumbprint for an OpenID Connect Identity Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html)

1. Create IAM OIDC Identity Provider:

   ```sh
   aws iam create-open-id-connect-provider \
     --url "https://token.actions.githubusercontent.com" \
     --client-id-list "sts.amazonaws.com" \
     --thumbprint-list "${OIDC_IDP_THUMBPRINT}"
   ```

1. Create IAM Role and Policy:

   ```sh
   export POLICY_ARN=$(aws iam create-policy --policy-name S3Access --policy-document file://aws_bucket_policy.json --query "Policy.Arn" --output text)
   export ROLE_ARN=$(aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://aws_role_for_ga.json --query "Role.Arn" --output text)
   aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"
   ```

   The value for `AWS_ROLE_ARN` environment variable for AWS GA workflow is available under `ROLE_ARN` variable.

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
   - [GitHub Docs - Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
   - [AWS - Creating OpenID Connect (OIDC) identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
   - [AWS - Creating a role for web identity or OpenID connect federation (console) ](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
   - [AWS - Obtaining the thumbprint for an OpenID Connect Identity Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html)
