# Quick Fix - Add OIDC Credentials for Infra Repo

## Problem
Your pipeline is failing because Azure AD doesn't recognize the `infra` repository for OIDC authentication.

## Solution - Add Federated Credentials

You need to add 3 federated credentials to your existing App Registration: **GitHubActionsEcommerce**

### Option 1: Azure Portal (Easiest)

1. Go to https://portal.azure.com
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click on **GitHubActionsEcommerce** (App ID: `0bfb2bb9-0df3-4032-8564-8551bb90ec01`)
4. In the left menu, click **Certificates & secrets**
5. Click on the **Federated credentials** tab
6. Click **+ Add credential**

Add these 3 credentials:

#### Credential 1: Develop Branch
- Federated credential scenario: **GitHub Actions deploying Azure resources**
- Organization: `IngesoftV-backend-microservices`
- Repository: `infra`
- Entity type: **Branch**
- GitHub branch name: `develop`
- Name: `github-infra-develop`
- Click **Add**

#### Credential 2: Main Branch
- Federated credential scenario: **GitHub Actions deploying Azure resources**
- Organization: `IngesoftV-backend-microservices`
- Repository: `infra`
- Entity type: **Branch**
- GitHub branch name: `main`
- Name: `github-infra-main`
- Click **Add**

#### Credential 3: Pull Requests
- Federated credential scenario: **GitHub Actions deploying Azure resources**
- Organization: `IngesoftV-backend-microservices`
- Repository: `infra`
- Entity type: **Pull request**
- Name: `github-infra-pr`
- Click **Add**

### Option 2: Azure CLI (If you have permissions)

Ask someone with **Owner** or **Application Administrator** role to run:

```bash
APP_ID="0bfb2bb9-0df3-4032-8564-8551bb90ec01"

# Develop branch
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-develop",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:ref:refs/heads/develop",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo develop"
}'

# Main branch
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo main"
}'

# Pull requests
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:pull_request",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo PRs"
}'
```

## After Adding the Credentials

1. Re-run your GitHub Actions workflow
2. The authentication should work now
3. Delete this file once everything works

## How to Verify

Check if the credentials were added:
```bash
az ad app federated-credential list --id "0bfb2bb9-0df3-4032-8564-8551bb90ec01" --query "[].{Name:name, Subject:subject}" -o table
```

You should see:
- `github-infra-develop` with subject `repo:IngesoftV-backend-microservices/infra:ref:refs/heads/develop`
- `github-infra-main` with subject `repo:IngesoftV-backend-microservices/infra:ref:refs/heads/main`
- `github-infra-pr` with subject `repo:IngesoftV-backend-microservices/infra:pull_request`
