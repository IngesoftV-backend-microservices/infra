#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Backend configuration (match with versions.tf and setup-backend.sh)
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstatetaller2"
CONTAINER_NAME="terraform-state"

echo -e "${RED}⚠️  WARNING: This will DESTROY the Terraform backend!${NC}"
echo -e "${RED}=============================================${NC}"
echo -e "${YELLOW}This will delete:${NC}"
echo -e "  - Storage Account: ${STORAGE_ACCOUNT}"
echo -e "  - Container: ${CONTAINER_NAME}"
echo -e "  - Resource Group: ${RESOURCE_GROUP}"
echo -e "  - ALL Terraform state files stored in the backend"
echo ""
echo -e "${RED}⚠️  This action CANNOT be undone!${NC}"
echo -e "${YELLOW}Make sure you have backups of your Terraform state if needed.${NC}"
echo ""

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
echo ""

# Check if resources exist
RESOURCES_EXIST=false
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    RESOURCES_EXIST=true
    echo -e "${YELLOW}Found Resource Group: ${RESOURCE_GROUP}${NC}"
else
    echo -e "${BLUE}Resource Group ${RESOURCE_GROUP} does not exist${NC}"
fi

if [ "$RESOURCES_EXIST" = true ]; then
    if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        echo -e "${YELLOW}Found Storage Account: ${STORAGE_ACCOUNT}${NC}"
    else
        echo -e "${BLUE}Storage Account ${STORAGE_ACCOUNT} does not exist${NC}"
    fi
fi

if [ "$RESOURCES_EXIST" = false ]; then
    echo -e "${GREEN}✅ Backend resources do not exist. Nothing to destroy.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}⚠️  Are you ABSOLUTELY SURE you want to destroy the backend?${NC}"
echo -e "${RED}This will delete ALL Terraform state files!${NC}"
read -p "Type 'DESTROY' (all caps) to confirm: " confirmation

if [ "$confirmation" != "DESTROY" ]; then
    echo -e "${YELLOW}❌ Destruction cancelled${NC}"
    exit 0
fi

# Delete Storage Account (this will also delete the container)
echo -e "${RED}🗑️  Deleting Storage Account: ${STORAGE_ACCOUNT}...${NC}"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    az storage account delete \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --yes \
        --output none
    echo -e "${GREEN}✅ Storage Account deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Storage Account does not exist${NC}"
fi

# Delete Resource Group (this will delete everything inside)
echo -e "${RED}🗑️  Deleting Resource Group: ${RESOURCE_GROUP}...${NC}"
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    az group delete \
        --name "$RESOURCE_GROUP" \
        --yes \
        --output none
    echo -e "${GREEN}✅ Resource Group deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Resource Group does not exist${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Backend destroyed successfully!${NC}"
echo -e "${BLUE}Note: If you want to use Terraform again, run: ./scripts/setup-backend.sh${NC}"

