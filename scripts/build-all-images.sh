#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check arguments
if [ "$#" -ne 2 ]; then
    print_error "Usage: $0 <environment> <github_org>"
    echo "  environment: dev or prod"
    echo "  github_org: GitHub organization name"
    exit 1
fi

ENVIRONMENT=$1
GITHUB_ORG=$2

# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Environment must be 'dev' or 'prod'"
    exit 1
fi

# Set ACR name based on environment
ACR_NAME="acrvingesoft${ENVIRONMENT}"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
IMAGE_TAG="${ENVIRONMENT}"

print_info "Building and pushing images for environment: $ENVIRONMENT"
print_info "GitHub Organization: $GITHUB_ORG"
print_info "ACR: $ACR_LOGIN_SERVER"
print_info "Image tag: $IMAGE_TAG"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "git is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
print_info "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run: az login"
    exit 1
fi

# Login to ACR
print_info "Logging in to ACR: $ACR_NAME..."
az acr login --name "$ACR_NAME" || {
    print_error "Failed to login to ACR. Make sure the ACR exists and you have permissions."
    exit 1
}

# Array of CORE services to build
# Business services (api-gateway, user-service, etc.) are built from their own repos
SERVICES=(
    "cloud-config"
    "service-discovery"
)

# Create temporary directory for cloning repos
TEMP_DIR=$(mktemp -d)
print_info "Created temporary directory: $TEMP_DIR"

# Cleanup function
cleanup() {
    print_info "Cleaning up temporary directory..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Build and push each service
TOTAL_SERVICES=${#SERVICES[@]}
CURRENT=0

for SERVICE in "${SERVICES[@]}"; do
    CURRENT=$((CURRENT + 1))
    print_info "[$CURRENT/$TOTAL_SERVICES] Processing $SERVICE..."

    SERVICE_DIR="$TEMP_DIR/$SERVICE"

    # Clone repository
    print_info "Cloning repository: $GITHUB_ORG/$SERVICE..."
    if ! git clone --depth 1 "https://github.com/$GITHUB_ORG/$SERVICE.git" "$SERVICE_DIR" 2>/dev/null; then
        print_error "Failed to clone $SERVICE repository"
        print_error "Make sure you have access to https://github.com/$GITHUB_ORG/$SERVICE"
        exit 1
    fi

    # Check if Dockerfile exists
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        print_warning "Dockerfile not found in $SERVICE. Skipping..."
        continue
    fi

    # Build image
    IMAGE_NAME="$ACR_LOGIN_SERVER/$SERVICE:$IMAGE_TAG"
    print_info "Building: $IMAGE_NAME"

    docker build -t "$IMAGE_NAME" "$SERVICE_DIR" || {
        print_error "Failed to build $SERVICE"
        exit 1
    }

    # Push image
    print_info "Pushing: $IMAGE_NAME"
    docker push "$IMAGE_NAME" || {
        print_error "Failed to push $SERVICE"
        exit 1
    }

    print_info "Successfully built and pushed $SERVICE"
    echo ""
done

print_info "========================================="
print_info "All images built and pushed successfully!"
print_info "========================================="
print_info "Environment: $ENVIRONMENT"
print_info "ACR: $ACR_LOGIN_SERVER"
print_info "Tag: $IMAGE_TAG"
print_info "Total services: $TOTAL_SERVICES"
