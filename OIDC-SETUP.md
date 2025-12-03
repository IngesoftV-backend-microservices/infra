# Azure OIDC Setup for Infra Repository

## Problem

The GitHub Actions workflow is failing with:
```
AADSTS700213: No matching federated identity record found for presented assertion subject
'repo:IngesoftV-backend-microservices/infra:ref:refs/heads/develop'
```

This happens because Azure AD doesn't have a federated credential configured for the `infra` repository.

## Solution

You need to add federated credentials in Azure AD for the `infra` repository.

### Option 1: Automated Setup (Recommended)

Run the provided script:

```bash
cd scripts
./setup-oidc-credentials.sh
```

This script will:
1. Find your existing App Registration
2. Create federated credentials for:
   - `develop` branch
   - `main` branch
   - Pull requests
3. Display the credentials you need to set in GitHub

### Option 2: Manual Setup via Azure Portal

1. **Navigate to Azure Portal**
   - Go to [Azure Portal](https://portal.azure.com)
   - Navigate to **Azure Active Directory** → **App registrations**
   - Find your app (likely named `github-oidc-app`)

2. **Add Federated Credentials**
   - Click on **Certificates & secrets**
   - Click on **Federated credentials** tab
   - Click **Add credential**

3. **Create credentials for each scenario:**

   **For develop branch:**
   - Federated credential scenario: `GitHub Actions deploying Azure resources`
   - Organization: `IngesoftV-backend-microservices`
   - Repository: `infra`
   - Entity type: `Branch`
   - GitHub branch name: `develop`
   - Name: `github-infra-develop`

   **For main branch:**
   - Organization: `IngesoftV-backend-microservices`
   - Repository: `infra`
   - Entity type: `Branch`
   - GitHub branch name: `main`
   - Name: `github-infra-main`

   **For Pull Requests:**
   - Organization: `IngesoftV-backend-microservices`
   - Repository: `infra`
   - Entity type: `Pull request`
   - Name: `github-infra-pr`

### Option 3: Azure CLI Commands

```bash
# Get your App ID
APP_ID=$(az ad app list --display-name "github-oidc-app" --query "[0].appId" -o tsv)

# Create credential for develop branch
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-develop",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:ref:refs/heads/develop",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo develop"
}'

# Create credential for main branch
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo main"
}'

# Create credential for pull requests
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "github-infra-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:IngesoftV-backend-microservices/infra:pull_request",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions OIDC for infra repo PRs"
}'
```

## Verify GitHub Secrets

Make sure these secrets are set in your `infra` repository:

```bash
gh secret list --repo IngesoftV-backend-microservices/infra
```

You should see:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `GH_PAT`

If they're missing, set them:

```bash
# Get values
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
APP_ID=$(az ad app list --display-name "github-oidc-app" --query "[0].appId" -o tsv)

# Set secrets
gh secret set AZURE_CLIENT_ID --body "$APP_ID" --repo IngesoftV-backend-microservices/infra
gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo IngesoftV-backend-microservices/infra
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID" --repo IngesoftV-backend-microservices/infra
```

## After Setup

Once the federated credentials are created, re-run your GitHub Actions workflow. It should now authenticate successfully.

## Troubleshooting

### List existing credentials
```bash
APP_ID=$(az ad app list --display-name "github-oidc-app" --query "[0].appId" -o tsv)
az ad app federated-credential list --id "$APP_ID" --query "[].{Name:name, Subject:subject}" -o table
```

### Delete a credential
```bash
az ad app federated-credential delete --id "$APP_ID" --federated-credential-id "github-infra-develop"
```

### Check App Registration permissions
Make sure your App Registration has:
- **Contributor** role on the subscription (for creating resources)
- Or specific permissions on the resource group

```bash
# Assign Contributor role to subscription
az role assignment create \
  --assignee "$APP_ID" \
  --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```
