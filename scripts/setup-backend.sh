#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Backend configuration (match with versions.tf)
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstatetaller2"
CONTAINER_NAME="terraform-state"
LOCATION="East US"

echo -e "${BLUE}🚀 Setting up Terraform Backend${NC}"
echo -e "${BLUE}=============================================${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install Azure CLI${NC}"
    exit 1
fi

# Check Azure login
echo -e "${YELLOW}🔍 Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Please run: az login${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✅ Azure authentication OK${NC}"
echo -e "${BLUE}Subscription ID: ${SUBSCRIPTION_ID}${NC}"

# Create Resource Group
echo -e "${BLUE}📦 Creating Resource Group: ${RESOURCE_GROUP}...${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Resource Group already exists${NC}"
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    echo -e "${GREEN}✅ Resource Group created${NC}"
fi

# Create Storage Account
echo -e "${BLUE}📦 Creating Storage Account: ${STORAGE_ACCOUNT}...${NC}"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Storage Account already exists${NC}"
else
    # Storage account names must be globally unique and lowercase
    # If the name is taken, you'll need to change it
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --output none
    echo -e "${GREEN}✅ Storage Account created${NC}"
fi

# Create Container
echo -e "${BLUE}📦 Creating Container: ${CONTAINER_NAME}...${NC}"
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query "[0].value" -o tsv)

if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$STORAGE_KEY" \
    &> /dev/null; then
    echo -e "${YELLOW}⚠️  Container already exists${NC}"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$STORAGE_KEY" \
        --output none
    echo -e "${GREEN}✅ Container created${NC}"
fi

echo -e "${GREEN}🎉 Backend setup complete!${NC}"
echo -e "${BLUE}You can now run: terraform init${NC}"
