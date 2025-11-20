#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Initializing Environment Configuration${NC}"
echo -e "${BLUE}=============================================${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments"

# Copy example files to actual tfvars
for env in dev prod; do
    echo -e "${BLUE}📦 Setting up ${env} environment...${NC}"

    if [ ! -f "${ENV_DIR}/${env}/terraform.tfvars" ]; then
        cp "${ENV_DIR}/${env}/terraform.tfvars.example" "${ENV_DIR}/${env}/terraform.tfvars"
        echo -e "${GREEN}✅ Created ${env}/terraform.tfvars${NC}"
    else
        echo -e "${YELLOW}⚠️  ${env}/terraform.tfvars already exists, skipping${NC}"
    fi
done

echo -e "${GREEN}🎉 Environment configuration initialized!${NC}"
echo -e "${YELLOW}⚠️  Review and customize the .tfvars files before deploying${NC}"
