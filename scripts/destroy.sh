#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ENV=${1:-dev}
TFVARS="environments/${ENV}/terraform.tfvars"

if [ ! -f "$TFVARS" ]; then
    echo -e "${RED}❌ Error: Environment file not found: $TFVARS${NC}"
    echo "Usage: $0 [dev|staging|prod]"
    exit 1
fi

echo -e "${RED}⚠️  WARNING: This will DESTROY all infrastructure for environment: ${ENV}${NC}"
echo -e "${RED}=============================================${NC}"
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform >= 1.5.0${NC}"
    exit 1
fi

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

echo -e "${GREEN}✅ Azure authentication OK${NC}"

# Show what will be destroyed
echo -e "${BLUE}📋 Showing what will be destroyed...${NC}"
terraform init -upgrade > /dev/null 2>&1
terraform plan -destroy -var-file="$TFVARS"

echo ""
echo -e "${RED}⚠️  Are you sure you want to DESTROY all infrastructure for ${ENV}?${NC}"
read -p "Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}❌ Destruction cancelled${NC}"
    exit 0
fi

# Destroy infrastructure
echo -e "${RED}🗑️  Destroying infrastructure...${NC}"
terraform destroy -auto-approve -var-file="$TFVARS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure destroyed successfully!${NC}"
    echo -e "${BLUE}Note: The Terraform state is still in the backend.${NC}"
    echo -e "${BLUE}To remove it completely, delete the state file from Azure Storage.${NC}"
else
    echo -e "${RED}❌ Destruction failed${NC}"
    exit 1
fi

