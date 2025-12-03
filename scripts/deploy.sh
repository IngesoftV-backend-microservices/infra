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

echo -e "${BLUE}🚀 Deploying Kubernetes Cluster${NC}"
echo -e "${BLUE}Environment: ${ENV}${NC}"
echo -e "${BLUE}=============================================${NC}"

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

# Initialize Terraform
echo -e "${BLUE}📦 Initializing Terraform...${NC}"
terraform init -backend-config="key=ecommerce-aks/${ENV}.tfstate" -reconfigure

# Validate configuration
echo -e "${BLUE}✅ Validating Terraform configuration...${NC}"
terraform validate

# Plan
echo -e "${BLUE}📋 Planning infrastructure changes...${NC}"
terraform plan -var-file="$TFVARS"

# Apply automatically
echo -e "${BLUE}🚀 Applying infrastructure changes...${NC}"
terraform apply -auto-approve -var-file="$TFVARS"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    echo -e "${BLUE}📊 Getting cluster information...${NC}"
    terraform output
    
    echo -e "${GREEN}🎉 Deployment complete!${NC}"
    echo -e "${BLUE}To get kubeconfig:${NC}"
    echo -e "${YELLOW}  terraform output -raw kube_config > ~/.kube/config-aks-${ENV}${NC}"
    echo -e "${YELLOW}  export KUBECONFIG=~/.kube/config-aks-${ENV}${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

