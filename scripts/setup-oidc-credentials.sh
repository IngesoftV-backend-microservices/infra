#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info "=== Azure OIDC Federated Credentials Setup for Infra Repo ==="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
print_info "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run: az login"
    exit 1
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_info "Current subscription: $SUBSCRIPTION_ID"

# Ask for App Registration name
read -p "Enter the App Registration name (default: github-oidc-app): " APP_NAME
APP_NAME=${APP_NAME:-github-oidc-app}

print_info "Looking for App Registration: $APP_NAME"

# Get App Registration details
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

if [ -z "$APP_ID" ]; then
    print_error "App Registration '$APP_NAME' not found."
    print_info "Please create it first or provide the correct name."
    exit 1
fi

print_info "Found App Registration ID: $APP_ID"

# Get Service Principal Object ID
SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)

if [ -z "$SP_OBJECT_ID" ]; then
    print_error "Service Principal not found for App ID: $APP_ID"
    print_info "Creating Service Principal..."
    az ad sp create --id "$APP_ID"
    SP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
fi

print_info "Service Principal Object ID: $SP_OBJECT_ID"

# GitHub Organization and Repository
GITHUB_ORG="IngesoftV-backend-microservices"
GITHUB_REPO="infra"

print_info "Configuring for: $GITHUB_ORG/$GITHUB_REPO"

# Create federated credentials for different branches and environments
declare -a CREDENTIALS=(
    "github-infra-develop:repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/develop"
    "github-infra-main:repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main"
    "github-infra-pr:repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request"
)

for CRED in "${CREDENTIALS[@]}"; do
    IFS=':' read -r CRED_NAME SUBJECT_PREFIX SUBJECT_VALUE <<< "$CRED"

    if [ "$SUBJECT_PREFIX" == "pull_request" ]; then
        SUBJECT="repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request"
    else
        SUBJECT="${SUBJECT_PREFIX}:${SUBJECT_VALUE}"
    fi

    print_info "Creating credential: $CRED_NAME"
    print_info "  Subject: $SUBJECT"

    # Check if credential already exists
    EXISTING=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CRED_NAME'].name" -o tsv)

    if [ -n "$EXISTING" ]; then
        print_warning "Credential '$CRED_NAME' already exists. Deleting it first..."
        az ad app federated-credential delete --id "$APP_ID" --federated-credential-id "$CRED_NAME" --yes 2>/dev/null || true
    fi

    # Create the federated credential
    az ad app federated-credential create \
        --id "$APP_ID" \
        --parameters "{
            \"name\": \"$CRED_NAME\",
            \"issuer\": \"https://token.actions.githubusercontent.com\",
            \"subject\": \"$SUBJECT\",
            \"audiences\": [
                \"api://AzureADTokenExchange\"
            ],
            \"description\": \"GitHub Actions OIDC for $GITHUB_REPO\"
        }" || print_error "Failed to create credential: $CRED_NAME"

    print_info "✅ Created: $CRED_NAME"
    echo ""
done

print_info "=== Federated Credentials Created Successfully ==="
echo ""
print_info "Listing all federated credentials for $APP_NAME:"
az ad app federated-credential list --id "$APP_ID" --query "[].{Name:name, Subject:subject}" -o table

echo ""
print_info "=== GitHub Secrets Configuration ==="
print_info "Make sure the following secrets are set in your GitHub repository:"
echo ""
echo "  AZURE_CLIENT_ID: $APP_ID"
echo "  AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "  AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
print_info "You can set them using GitHub CLI:"
echo "  gh secret set AZURE_CLIENT_ID --body '$APP_ID' --repo $GITHUB_ORG/$GITHUB_REPO"
echo "  gh secret set AZURE_TENANT_ID --body '$(az account show --query tenantId -o tsv)' --repo $GITHUB_ORG/$GITHUB_REPO"
echo "  gh secret set AZURE_SUBSCRIPTION_ID --body '$SUBSCRIPTION_ID' --repo $GITHUB_ORG/$GITHUB_REPO"
echo ""
print_info "Done!"
